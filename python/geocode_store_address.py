import pymysql
import requests
import os
from dotenv import load_dotenv
import logging

# 환경 변수 로드
load_dotenv()

# 로깅 설정
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Kakao REST API 키 설정 (환경 변수에서 가져오기)
KAKAO_API_KEY = os.getenv('KAKAO_API_KEY', '6468d726fb9dca754c7325a4289a4156')

# MariaDB 연결 설정 (환경 변수에서 가져오기)
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', '1111')
DB_NAME = os.getenv('DB_NAME', 'bapsim')

# Kakao 지오코딩 API 호출 함수
def get_geocode(address):
    headers = {
        'Authorization': f'KakaoAK {KAKAO_API_KEY}'
    }
    params = {
        'query': address
    }
    url = 'https://dapi.kakao.com/v2/local/search/address.json'
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        result = response.json()
        if result['documents']:
            latitude = result['documents'][0]['y']
            longitude = result['documents'][0]['x']
            return latitude, longitude
        else:
            logger.warning(f"No geocode found for address: {address}")
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error for address '{address}': {e}")
    return None, None

# MariaDB에 연결하고 가게 정보 업데이트
def update_store_geocodes():
    try:
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = connection.cursor()

        # stores 테이블에서 모든 가게의 주소 가져오기
        cursor.execute("SELECT id, location FROM stores")
        stores = cursor.fetchall()

        # 각 가게의 주소를 지오코딩하고 결과를 업데이트
        for store in stores:
            store_id = store['id']
            address = store['location']
            latitude, longitude = get_geocode(address)

            if latitude and longitude:
                # 위도와 경도를 stores 테이블에 업데이트
                cursor.execute(
                    """
                    UPDATE stores
                    SET latitude = %s, longitude = %s
                    WHERE id = %s
                    """,
                    (latitude, longitude, store_id)
                )
                connection.commit()
                logger.info(f"Updated store {store_id} with latitude {latitude} and longitude {longitude}")
            else:
                logger.warning(f"Failed to get geocode for store {store_id}")

    except pymysql.MySQLError as e:
        logger.error(f"Database error: {e}")
    finally:
        if connection:
            connection.close()

if __name__ == '__main__':
    update_store_geocodes()
