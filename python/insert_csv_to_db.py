import pymysql
import pandas as pd

# CSV 파일 읽기
file_name = "./data/dish_db.csv"
dish_df = pd.read_csv(file_name)

# MariaDB 연결 설정
connection = pymysql.connect(
    host='localhost',
    user='root',
    password='1111',  # 설정한 root 비밀번호
    database='bapsim'
)

cursor = connection.cursor()

# 데이터 삽입
for _, row in dish_df.iterrows():
    sql = """
    INSERT INTO dishes (name, main_ingredients, category, flavor, characteristics, season, cooking_method)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    cursor.execute(sql, (
        row['이름'],
        row['주요재료'],
        row['분류'],
        row['맛'],
        row['특징'],
        row['계절'],
        row['조리방법']
    ))

# 변경사항 저장
connection.commit()

# 연결 닫기
cursor.close()
connection.close()
