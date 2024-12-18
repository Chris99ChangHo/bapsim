import pandas as pd
import pymysql

# MariaDB 연결 설정
def get_db_connection():
    connection = pymysql.connect(
        host='localhost',  # 또는 MariaDB 서버의 주소
        user='root',
        password='1111',  # MariaDB 비밀번호
        db='bapsim'
    )
    return connection

# MariaDB에서 new_dishes 데이터를 가져오는 함수
def get_new_dishes_from_db():
    connection = get_db_connection()
    try:
        query = "SELECT name FROM new_dishes"
        df = pd.read_sql(query, connection)
        return df['name'].tolist()  # 'name' 열만 가져오기
    finally:
        connection.close()

# CSV 파일에서 데이터를 가져오는 함수
def get_dishes_from_csv(file_path):
    csv_data = pd.read_csv(file_path)
    return csv_data['이름'].tolist()  # '이름' 열만 가져오기

# 데이터 비교 함수
def compare_dishes(csv_file_path):
    # CSV 파일에서 데이터 가져오기
    csv_dishes = get_dishes_from_csv(csv_file_path)
    
    # MariaDB에서 new_dishes 테이블 데이터 가져오기
    db_dishes = get_new_dishes_from_db()
    
    # 두 리스트 비교
    common_dishes = set(csv_dishes).intersection(db_dishes)
    missing_from_db = set(csv_dishes) - set(db_dishes)
    missing_from_csv = set(db_dishes) - set(csv_dishes)

    # 결과 출력
    print(f"Common dishes: {common_dishes}")
    print(f"Dishes missing from MariaDB: {missing_from_db}")
    print(f"Dishes missing from CSV: {missing_from_csv}")

# CSV 파일 경로를 지정
csv_file_path = './data/dish_db.csv'  # 실제 CSV 파일 경로로 수정하세요

# 비교 실행
compare_dishes(csv_file_path)
