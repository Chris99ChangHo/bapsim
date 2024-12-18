from flask import Flask, request, jsonify, g
import pandas as pd
import pymysql
import logging
from flask_cors import CORS
from dotenv import load_dotenv
import os
import math

# 환경 변수 로드
load_dotenv()

# Flask 서버 설정
app = Flask(__name__)
CORS(app)

# 로깅 설정
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

# MariaDB 연결 관리
def get_db_connection():
    if 'db' not in g:
        g.db = pymysql.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            user=os.getenv('DB_USER', 'root'),
            password=os.getenv('DB_PASSWORD', '1111'),
            database=os.getenv('DB_NAME', 'bapsim')
        )
    return g.db

@app.teardown_appcontext
def close_db_connection(exception):
    db = g.pop('db', None)
    if db is not None:
        db.close()

# 거리 계산 함수 (Haversine formula)
def calculate_distance(lat1, lon1, lat2, lon2):
    try:
        if pd.isna(lat1) or pd.isna(lon1) or pd.isna(lat2) or pd.isna(lon2):
            return float('inf')  # 거리 계산 불가 시 무한대로 처리
        R = 6371  # 지구 반지름(km)
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = math.sin(delta_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c
    except Exception as e:
        logger.error(f"Error in distance calculation: {e}")
        return float('inf')

# /stores/<int:store_id>/dishes 엔드포인트
@app.route('/stores/<int:store_id>/dishes', methods=['GET'])
def fetch_dishes_by_store(store_id):
    try:
        db_connection = get_db_connection()
        cursor = db_connection.cursor(pymysql.cursors.DictCursor)
        
        # Query to fetch dishes for a specific store
        cursor.execute("""
            SELECT d.name, d.image_url, CAST(sd.price AS SIGNED) as price, d.cooking_method
            FROM store_dishes sd
            JOIN dishes d ON sd.dish_id = d.id
            WHERE sd.store_id = %s
        """, (store_id,))
        dishes = cursor.fetchall()

        # Return the result as JSON
        return jsonify(dishes)
    except Exception as e:
        logger.error(f"Error fetching dishes for store {store_id}: {e}")
        return jsonify({"error": f"Failed to fetch dishes for store {store_id}"}), 500
    
@app.route('/fetch_stores', methods=['GET'])
def fetch_stores():
    try:
        db_connection = get_db_connection()
        cursor = db_connection.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT id, name, location, telephone_number, latitude, longitude FROM stores")
        stores = cursor.fetchall()
        return jsonify(stores)
    except Exception as e:
        logger.error(f"Error fetching stores: {e}")
        return jsonify({"error": "Failed to fetch stores"}), 500

# /search_dishes 엔드포인트
@app.route('/search_dishes', methods=['GET'])
def search_dishes():
    query = request.args.get('query', '')
    try:
        db_connection = get_db_connection()
        cursor = db_connection.cursor(pymysql.cursors.DictCursor)
        cursor.execute("""
            SELECT d.name, s.name as store_name, CAST(sd.price AS SIGNED) as price, d.image_url
            FROM dishes d
            JOIN store_dishes sd ON d.id = sd.dish_id
            JOIN stores s ON sd.store_id = s.id
            WHERE d.name LIKE %s
        """, ('%' + query + '%',))
        results = cursor.fetchall()
        return jsonify(results)
    except Exception as e:
        logger.error(f"Error searching dishes: {e}")
        return jsonify({"error": "Failed to search dishes"}), 500

# 반찬 추천 로직
def recommend_dishes(user_dishes, dish_df, num_recommendations, include_soup_option=False, selected_season=None, vegan_only=False):
    try:
        logger.debug("Starting recommendation process")
        logger.debug(f"User dishes: {user_dishes}, Recommendations needed: {num_recommendations}, Include soup: {include_soup_option}")

        # 사용자 반찬 정보와 후보 데이터 생성
        user_dishes_info = dish_df[dish_df['name'].isin(user_dishes)]
        candidate_dishes = dish_df[~dish_df['name'].isin(user_dishes)].copy()
        logger.debug(f"Initial candidate dishes count: {len(candidate_dishes)}")

        # 비건 필터 적용
        if vegan_only:
            candidate_dishes = candidate_dishes[candidate_dishes['characteristics'].str.contains('비건', na=False)]

        candidate_dishes['score'] = 0

        # 사용자 기반 점수 계산
        if not user_dishes_info.empty:
            user_categories = user_dishes_info['category'].unique()
            for _, user_dish in user_dishes_info.iterrows():
                if 'flavor' in candidate_dishes.columns and 'flavor' in user_dish:
                    candidate_dishes.loc[candidate_dishes['flavor'] != user_dish['flavor'], 'score'] += 3
                    candidate_dishes.loc[candidate_dishes['flavor'] == user_dish['flavor'], 'score'] += 2
                    candidate_dishes.loc[~candidate_dishes['category'].isin(user_categories), 'score'] += 3

        # 계절 필터 적용
        if selected_season:
            candidate_dishes.loc[candidate_dishes['season'] == selected_season, 'score'] += 2
            logger.debug(f"Season filter applied. Season: {selected_season}")

        # 국물요리 포함 여부
        top_soup = pd.DataFrame()
        if include_soup_option:
            soup_dishes = candidate_dishes[candidate_dishes['characteristics'].str.contains('국물요리', na=False)]
            if not soup_dishes.empty:
                top_soup = soup_dishes.sort_values(by='score', ascending=False).head(1)
                candidate_dishes = candidate_dishes[~candidate_dishes['characteristics'].str.contains('국물요리', na=False)]
                logger.debug(f"Soup dishes count after selection: {len(top_soup)}")
        else:
            # 국물요리 완전히 제외
            candidate_dishes = candidate_dishes[~candidate_dishes['characteristics'].str.contains('국물요리', na=False)]

        # '전'으로 끝나는 반찬 중복 방지
        jeon_dishes = candidate_dishes[candidate_dishes['name'].str.endswith('전')]
        top_jeon = pd.DataFrame()
        if not jeon_dishes.empty:
            top_jeon = jeon_dishes.sort_values(by='score', ascending=False).head(1)
            candidate_dishes = candidate_dishes[~candidate_dishes['name'].str.endswith('전')]
        logger.debug(f"'전' dishes count after selection: {len(top_jeon)}")

        # 나머지 추천 계산
        num_to_recommend = num_recommendations - len(top_soup) - len(top_jeon)
        top_recommendations = pd.concat([
            top_soup,
            top_jeon,
            candidate_dishes.sort_values(by='score', ascending=False).head(num_to_recommend)
        ])

        # 중복 제거 (이름 기준)
        top_recommendations = top_recommendations.drop_duplicates(subset='name')

        # 부족한 개수 채우기
        while len(top_recommendations) < num_recommendations:
            remaining_candidates = candidate_dishes[~candidate_dishes['name'].isin(top_recommendations['name'])]
            if not remaining_candidates.empty:
                sampled = remaining_candidates.sample(1, random_state=42)
                top_recommendations = pd.concat([top_recommendations, sampled]).drop_duplicates(subset='name')
            else:
                logger.warning("No more unique candidates to fill recommendations.")
                break

        # 최종 검증 및 개수 보장
        top_recommendations = top_recommendations.head(num_recommendations)
        logger.debug(f"Final recommendations count: {len(top_recommendations)}")

        # 결과 반환
        return top_recommendations[['name', 'store_name', 'latitude', 'longitude', 'price', 'image_url', 'score']]
    except Exception as e:
        logger.error(f"Error in recommend_dishes: {e}")
        raise

@app.route('/recommend', methods=['POST'])
def recommend():
    try:
        data = request.get_json()
        logger.debug(f"Received data: {data}")

        # 입력 값 검증 및 기본값 설정
        user_dishes = data.get('user_dishes', [])
        num_recommendations = data.get('num_recommendations', 5)
        if num_recommendations <= 0:
            logger.warning(f"Invalid num_recommendations ({num_recommendations}). Setting to default value 5.")
            num_recommendations = 5

        include_soup_option = data.get('include_soup_option', True)
        selected_season = data.get('selected_season', None)
        vegan_only = data.get('vegan_only', False)

        user_lat = data.get('user_lat', 37.4783)
        user_lon = data.get('user_lon', 126.9516)

        db_connection = get_db_connection()
        cursor = db_connection.cursor(pymysql.cursors.DictCursor)
        cursor.execute("""
            SELECT s.name as store_name, s.latitude, s.longitude,
                   d.name, d.image_url, CAST(sd.price AS SIGNED) as price, d.season, d.category, d.characteristics
            FROM store_dishes sd
            JOIN stores s ON sd.store_id = s.id
            JOIN dishes d ON sd.dish_id = d.id
        """)
        dish_data = cursor.fetchall()
        dish_df = pd.DataFrame(dish_data)

        # 건너뛰기 로직 사용 여부 확인
        if not user_dishes and selected_season is None:
            logger.info("No user dishes or selected season provided. Using skip logic.")
            recommendations = recommend_dishes_skip(dish_df, num_recommendations, user_lat, user_lon)
        else:
            recommendations = recommend_dishes(
                user_dishes, dish_df, num_recommendations,
                include_soup_option, selected_season, vegan_only
            )

        # 필요한 데이터만 반환
        result = recommendations[['name', 'store_name', 'price', 'image_url']].to_dict(orient='records')
        return jsonify(result)
    except Exception as e:
        logger.error(f"Unhandled error: {e}")
        return jsonify({"error": f"An unexpected error occurred: {e}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
