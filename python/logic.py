from flask import Flask, request, jsonify, g
import pandas as pd
import pymysql
import logging
from flask_cors import CORS
from logging.handlers import RotatingFileHandler
from dotenv import load_dotenv
import os
import math

# 환경 변수 로드
load_dotenv()

# Flask 서버 설정
app = Flask(__name__)
CORS(app)

# 로깅 설정
if not os.path.exists('logs'):
    os.mkdir('logs')

debug_handler = RotatingFileHandler('logs/debug.log', maxBytes=10240, backupCount=10)
debug_handler.setLevel(logging.DEBUG)

error_handler = RotatingFileHandler('logs/error.log', maxBytes=10240, backupCount=10)
error_handler.setLevel(logging.ERROR)

formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
debug_handler.setFormatter(formatter)
error_handler.setFormatter(formatter)

app.logger.addHandler(debug_handler)
app.logger.addHandler(error_handler)

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
        app.logger.error(f"Error in distance calculation: {e}")
        return float('inf')

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
        app.logger.error(f"Error searching dishes: {e}")
        return jsonify({"error": "Failed to search dishes"}), 500

# 추천 로직
def recommend_dishes(user_dishes, dish_df, num_recommendations=5, include_soup_option=True, selected_season=None, vegan_only=False, user_lat=None, user_lon=None):
    try:
        # 사용자 반찬 정보
        user_dishes_info = dish_df[dish_df['name'].isin(user_dishes)]
        candidate_dishes = dish_df[~dish_df['name'].isin(user_dishes)].copy()

        if vegan_only:
            candidate_dishes = candidate_dishes[candidate_dishes['characteristics'].str.contains('비건', na=False)]

        candidate_dishes['score'] = 0

        # 주요 재료 조화 점수
        if not user_dishes_info.empty:
            user_main_ingredients = set(
                ','.join(user_dishes_info['main_ingredients'].dropna().astype(str)).split(',')
            )
            candidate_dishes['main_ingredients_score'] = candidate_dishes['main_ingredients'].apply(
                lambda x: len(set(str(x).split(',')).intersection(user_main_ingredients))
            ).apply(
                lambda match_count: 1 if match_count > 0 else 2  # 겹치면 +1, 다양하면 +2
            )
            candidate_dishes['score'] += candidate_dishes['main_ingredients_score']

        # 조리 방식 다양성 점수
        user_cooking_methods = set(user_dishes_info['cooking_method'].dropna())
        candidate_dishes['cooking_method_score'] = candidate_dishes['cooking_method'].apply(
            lambda x: 2 if x not in user_cooking_methods else 1  # 새로운 방식 +2, 기존 방식 +1
        )
        candidate_dishes['score'] += candidate_dishes['cooking_method_score']

        # 카테고리 다양성 점수
        user_categories = set(user_dishes_info['category'].dropna())
        candidate_dishes['category_score'] = candidate_dishes['category'].apply(
            lambda x: 2 if x not in user_categories else 1  # 새로운 카테고리 +2, 기존 카테고리 +1
        )
        candidate_dishes['score'] += candidate_dishes['category_score']

        # 맛 조화 점수
        if not user_dishes_info.empty:
            for _, user_dish in user_dishes_info.iterrows():
                if 'flavor' in candidate_dishes.columns and 'flavor' in user_dish:
                    candidate_dishes.loc[candidate_dishes['flavor'] != user_dish['flavor'], 'score'] += 2  # 다른 맛 +3
                    candidate_dishes.loc[candidate_dishes['flavor'] == user_dish['flavor'], 'score'] += 1  # 같은 맛 +1

        # 계절 조화 점수
        if selected_season:
            candidate_dishes.loc[candidate_dishes['season'] == selected_season, 'score'] += 2

        # 국물요리 포함 여부 처리
        top_soup = pd.DataFrame()
        if include_soup_option:
            soup_dishes = candidate_dishes[candidate_dishes['characteristics'].str.contains('국물요리', na=False)]
            if not soup_dishes.empty:
                # 국물요리 중 하나만 추천
                top_soup = soup_dishes.sort_values(by='score', ascending=False).head(1)
                # 추천된 국물요리를 후보 목록에서 제거
                candidate_dishes = candidate_dishes[~candidate_dishes.index.isin(top_soup.index)]
            # 국물요리 외 나머지 추천 개수 계산
            num_to_recommend = num_recommendations - 1  # 국물요리 하나를 제외한 나머지 개수
            non_soup_recommendations = candidate_dishes.sort_values(by='score', ascending=False).head(num_to_recommend)
            top_recommendations = pd.concat([top_soup, non_soup_recommendations])
        else:
            # 국물요리를 제외하고 추천
            candidate_dishes = candidate_dishes[~candidate_dishes['characteristics'].str.contains('국물요리', na=False)]
            top_recommendations = candidate_dishes.sort_values(by='score', ascending=False).head(num_recommendations)

        # 중복 제거 및 거리 계산
        top_recommendations = top_recommendations.drop_duplicates(subset='name').head(num_recommendations)
        if user_lat is not None and user_lon is not None:
            top_recommendations['distance'] = top_recommendations.apply(
                lambda row: calculate_distance(user_lat, user_lon, row['latitude'], row['longitude']),
                axis=1
            )
            top_recommendations = top_recommendations.sort_values(by=['score', 'distance'], ascending=[False, True])

        # 최종 결과 반환
        return top_recommendations[['name', 'store_name', 'latitude', 'longitude', 'price', 'image_url', 'score', 'distance']]
    except Exception as e:
        app.logger.error(f"Error in recommend_dishes: {e}")
        raise

# /recommend 엔드포인트
@app.route('/recommend', methods=['POST'])
def recommend():
    try:
        data = request.get_json()
        app.logger.debug(f"Received data: {data}")

        user_dishes = data.get('user_dishes', [])
        num_recommendations = data.get('num_recommendations', 5)
        include_soup_option = data.get('include_soup_option', True)
        selected_season = data.get('selected_season', None)
        vegan_only = data.get('vegan_only', False)

        user_lat = data.get('user_lat', 37.4783)
        user_lon = data.get('user_lon', 126.9516)

        db_connection = get_db_connection()
        cursor = db_connection.cursor(pymysql.cursors.DictCursor)
        cursor.execute("""
            SELECT s.name as store_name, s.latitude, s.longitude,
                   d.name, d.image_url, CAST(sd.price AS SIGNED) as price, d.season, d.category, d.characteristics,
                   d.main_ingredients, d.cooking_method, d.flavor
            FROM store_dishes sd
            JOIN stores s ON sd.store_id = s.id
            JOIN dishes d ON sd.dish_id = d.id
        """)
        dish_data = cursor.fetchall()
        dish_df = pd.DataFrame(dish_data)

        recommendations = recommend_dishes(
            user_dishes, dish_df, num_recommendations,
            include_soup_option, selected_season, vegan_only, user_lat, user_lon
        )

        # 필요한 데이터만 반환
        app.logger.debug(f"Recommendations: {recommendations}")

        result = recommendations[['name', 'store_name', 'price', 'image_url', 'distance']].to_dict(orient='records')
        return jsonify(result)
    except Exception as e:
        app.logger.error(f"Unhandled error: {e}")
        return jsonify({"error": f"An unexpected error occurred: {e}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

# ----------------------------------------------------------------------------------------------------------------------------
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

# 추천 로직
def recommend_dishes(user_dishes, dish_df, num_recommendations, include_soup_option, selected_season=None, vegan_only=False):
    try:
        # 사용자 반찬 정보
        user_dishes_info = dish_df[dish_df['name'].isin(user_dishes)]
        candidate_dishes = dish_df[~dish_df['name'].isin(user_dishes)].copy()

        if vegan_only:
            candidate_dishes = candidate_dishes[candidate_dishes['characteristics'].str.contains('비건', na=False)]

        candidate_dishes['score'] = 0

        # 사용자 반찬 정보 기반 점수 계산
        if not user_dishes_info.empty:
            user_categories = user_dishes_info['category'].unique()
            for _, user_dish in user_dishes_info.iterrows():
                if 'flavor' in candidate_dishes.columns and 'flavor' in user_dish:
                    candidate_dishes.loc[candidate_dishes['flavor'] != user_dish['flavor'], 'score'] += 3
                    candidate_dishes.loc[candidate_dishes['flavor'] == user_dish['flavor'], 'score'] += 2
                    candidate_dishes.loc[~candidate_dishes['category'].isin(user_categories), 'score'] += 3

        # 계절 필터 추가
        if selected_season:
            candidate_dishes.loc[candidate_dishes['season'] == selected_season, 'score'] += 2

        # 국물요리 포함 여부 처리
        top_soup = pd.DataFrame()
        if include_soup_option:
            soup_dishes = candidate_dishes[candidate_dishes['characteristics'].str.contains('국물요리', na=False)]
            if not soup_dishes.empty:
                # 국물요리 중 하나만 추천
                top_soup = soup_dishes.sort_values(by='score', ascending=False).head(1)
                # 추천된 국물요리를 후보 목록에서 제거
                candidate_dishes = candidate_dishes[~candidate_dishes.index.isin(top_soup.index)]

        # 최종 추천 결과
        num_to_recommend = num_recommendations - len(top_soup)
        top_recommendations = pd.concat([
            top_soup,
            candidate_dishes.sort_values(by='score', ascending=False).head(num_to_recommend)
        ])

        # 중복 제거 및 최종 개수 맞추기
        top_recommendations = top_recommendations.drop_duplicates(subset='name').head(num_recommendations)

        # 부족한 추천 개수 채우기
        while len(top_recommendations) < num_recommendations:
            additional_candidates = candidate_dishes[~candidate_dishes['name'].isin(top_recommendations['name'])]
            if not additional_candidates.empty:
                sampled = additional_candidates.sample(1, random_state=42)
                top_recommendations = pd.concat([top_recommendations, sampled]).drop_duplicates(subset='name')
            else:
                break

        # 국물요리 중복 방지
        if include_soup_option:
            soup_count = top_recommendations['characteristics'].str.contains('국물요리', na=False).sum()
            if soup_count > 1:
                logger.warning("Duplicate soup dishes detected. Restricting to one soup dish.")
                top_recommendations = top_recommendations[
                    ~((top_recommendations['characteristics'].str.contains('국물요리', na=False)) &
                      (top_recommendations.index != top_soup.index[0]))
                ]

        # 최종 결과 반환
        return top_recommendations[['name', 'store_name', 'latitude', 'longitude', 'price', 'image_url', 'score']]
    except Exception as e:
        logger.error(f"Error in recommend_dishes: {e}")
        raise

# /recommend 엔드포인트
@app.route('/recommend', methods=['POST'])
def recommend():
    try:
        data = request.get_json()
        logger.debug(f"Received data: {data}")

        user_dishes = data.get('user_dishes', [])
        num_recommendations = data.get('num_recommendations', 5)
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

        recommendations = recommend_dishes(
            user_dishes, dish_df, num_recommendations,
            include_soup_option, selected_season, vegan_only
        )

        # 거리 계산
        recommendations['distance'] = recommendations.apply(
            lambda row: calculate_distance(user_lat, user_lon, row['latitude'], row['longitude']),
            axis=1
        )
        recommendations = recommendations.sort_values(by='distance')

        # 필요한 데이터만 반환
        result = recommendations[['name', 'store_name', 'price', 'image_url', 'distance']].to_dict(orient='records')
        return jsonify(result)
    except Exception as e:
        logger.error(f"Unhandled error: {e}")
        return jsonify({"error": f"An unexpected error occurred: {e}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
