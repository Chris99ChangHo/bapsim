# f"https://www.google.com/search?q={dish_name}+이미지&tbm=isch" # 구글 이미지 검색 URL
# f"https://search.naver.com/search.naver?where=image&sm=tab_jum&query={dish_name}" # 네이버 이미지 검색 URL

import requests
from bs4 import BeautifulSoup
import pymysql
import time
import csv
import os

# MariaDB 연결
db_connection = pymysql.connect(
    host='localhost',
    user='root',
    password='1111',
    database='bapsim',
    charset='utf8mb4'
)

cursor = db_connection.cursor()

# 결과 저장 디렉토리
output_folder = "data"
if not os.path.exists(output_folder):
    os.mkdir(output_folder)

output_file = os.path.join(output_folder, "dish_images.csv")

# 원본 이미지 URL 가져오기
def fetch_image_url(dish_name):
    search_url = f"https://search.naver.com/search.naver?where=image&sm=tab_jum&query={dish_name}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Gecko/20100101 Firefox/91.0"
    }
    try:
        response = requests.get(search_url, headers=headers)
        
        if response.status_code != 200:
            print(f"Failed to fetch image for {dish_name}. Status code: {response.status_code}")
            return None

        soup = BeautifulSoup(response.text, "html.parser")
        image_tags = soup.find_all("img")

        if not image_tags:
            print(f"No images found for {dish_name}")
            return None

        # 첫 번째 이미지 URL 반환
        for img_tag in image_tags:
            thumbnail_url = img_tag.get("src")
            if thumbnail_url:
                return thumbnail_url
    except Exception as e:
        print(f"Error fetching image for {dish_name}: {e}")
    return None

# 반찬 이미지 업데이트 및 CSV 파일 저장
def update_dish_image(dish_name, writer):
    image_url = fetch_image_url(dish_name)
    if image_url:
        try:
            query = "UPDATE dishes SET image_url = %s WHERE name = %s"
            cursor.execute(query, (image_url, dish_name))
            db_connection.commit()
            print(f"Updated image for {dish_name}: {image_url}")
            writer.writerow({"dish_name": dish_name, "image_url": image_url})
        except pymysql.MySQLError as e:
            print(f"Database error while updating {dish_name}: {e}")
    else:
        print(f"No image found for {dish_name}")

# CSV 파일 작성 및 데이터베이스 작업
with open(output_file, mode="w", newline="", encoding="utf-8") as csvfile:
    fieldnames = ["dish_name", "image_url"]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()

    try:
        # 테이블에서 반찬 이름 가져오기
        cursor.execute("SELECT name FROM dishes")
        dish_names = cursor.fetchall()

        # 각 반찬 이름에 대해 이미지 업데이트 및 CSV 저장
        for dish in dish_names:
            update_dish_image(dish[0], writer)
            time.sleep(1)  # 요청 간 대기 시간
    except pymysql.MySQLError as e:
        print(f"Error fetching dishes from database: {e}")

# DB 연결 종료
cursor.close()
db_connection.close()

print(f"CSV file saved to: {output_file}")
