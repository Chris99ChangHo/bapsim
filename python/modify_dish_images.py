import csv
import pymysql

# MariaDB 연결
db_connection = pymysql.connect(
    host='localhost',
    user='root',
    password='1111',
    database='bapsim',
    charset='utf8mb4'
)
cursor = db_connection.cursor()

# CSV 파일 읽고 DB 업데이트
csv_file = 'data/dish_images.csv'
with open(csv_file, mode='r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    for row in reader:
        dish_name = row['dish_name']
        image_url = row['image_url']
        query = "UPDATE dishes SET image_url = %s WHERE name = %s"
        cursor.execute(query, (image_url, dish_name))
        print(f"Updated {dish_name} with URL: {image_url}")

db_connection.commit()
cursor.close()
db_connection.close()
