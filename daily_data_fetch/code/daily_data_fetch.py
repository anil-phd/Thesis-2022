import requests
import multiprocessing as mp
import xml.etree.ElementTree as ET
import datetime
from datetime import date
import pandas as pd
import time
from configparser import ConfigParser
import logging
import warnings
warnings.filterwarnings('ignore')
import psycopg2 as pg
from sqlalchemy.sql import text
from sqlalchemy import create_engine

log_file = "log_" + str(date.today().strftime("%d_%m_%Y"))
logging.basicConfig(filename=f'./Log/{log_file}.log', encoding='utf-8', level=logging.INFO)

config = ConfigParser()
config.read('./config/config.ini')

#--------------------------------------------------------------------------
#                         :: Database Stuff
#--------------------------------------------------------------------------

db =config['DataBase']['databasename']
password = config['DataBase']['pwd']
host = config['DataBase']['host']
user = config['DataBase']['uid']

#con = pg.connect("dbname="+db+" user="+user+" host="+host+" port='5432' password="+password+"") # confio
engine = create_engine(f'postgresql+psycopg2://{user}:{password}@{host}/{db}')



#----------------------------------------------------------------------------
#                          ::DB Push ::
#-----------------------------------------------------------------------------

raw_data_push_table_name = config['DataBase']['rawdatapushtablename'] # config
err_or_exp_push_table_name = config['DataBase']['errorexppushtablename'] #config


#-----------------------------------------------------------------------------
'''
  Function: Fetches data for a meter for current date minus 2 date
  Input: Meter Number
  Output: Dataframe

'''

def fetch_data(meter):
  logging.info(f'Fetching data for meter {meter} at: {datetime.datetime.now()}')
  date = datetime.date.fromordinal(datetime.date.today().toordinal() - 2).strftime("%F")  # the day before yesterday
  date = str(date)+'T00:00:00'

  l1 =[]
  l2 =[]
  l3 = []

  try:

    url = "https://tpwesternodisha-svc-v2.smartcmobile.com/cis/api/1/AMRIntervalSetTPM?ImFdate="+str(date)+"&ImTdate="+str(date)+"&ImSernr="+str(meter)+""
    payload = {}
    headers = {
      'Cookie': 'ApplicationGatewayAffinity=bf31b527b1fb5a2b66ac7679228aa726; ApplicationGatewayAffinityCORS=bf31b527b1fb5a2b66ac7679228aa726'
    }

    response = requests.request("GET", url, headers=headers, data=payload)
    data = response.json()
    if data['status']['code'] == 200:
      for i in data['data']['results']:
        if i['meterno'] != '':
          Meterno = str(i['meterno'])
          Kwhimp = str(i['kwhimp'])

          if ((i['zinterval'] == '24:00:00') | (i['zinterval'] == '240000')):
            date_str = i['zdate'] + ' ' + '00:00:00'
            date_str = pd.to_datetime(date_str, format='%d.%m.%Y %H:%M:%S') + datetime.timedelta(days=1)
            Usagedate =str (date_str)
          else:
            date_str = i['zdate'] + ' ' + i['zinterval']
            date_str = pd.to_datetime(date_str, format='%d.%m.%Y %H:%M:%S')
            Usagedate = str(date_str)
          l1.append(Usagedate)
          l2.append(Meterno)
          l3.append(Kwhimp)

      temp=pd.DataFrame(data={'meternumber': l2, 'usagedate': l1, 'consumption': l3})
      if len(temp)>0:
        temp.to_sql(raw_data_push_table_name, con=engine, if_exists='append', index=False,chunksize=100,method='multi')

    else:
      err_msz = (str(data['status']['message']))
      err_meters = str(meter)


      data= {'meter':[err_meters],'err_tye':[err_msz]}
      pd.DataFrame(data=data).to_sql(err_or_exp_push_table_name, con=engine, if_exists='append', index=False,chunksize=100,method='multi')


  except Exception as e:
    exp_meter = str(meter)
    exp_msz = (str(e))
    data1 = {'meter': [exp_meter], 'err_tye': [exp_msz]}
    pd.DataFrame(data=data1).to_sql(err_or_exp_push_table_name, con=engine,if_exists='append', index=False,chunksize=100,method='multi')


#--------------------------------------------------------------

#---------------------------------------------------------------
if __name__ == "__main__":

  logging.info(f'Starting API Data Fetch: {datetime.datetime.now()}')

  logging.info(f'Extracting list of meters at: {datetime.datetime.now()}')
  q = config['SQLInput']['address'] #config
  query = open(q, 'r')
  with engine.connect() as conn:
    latest_meters = latest_meters = pd.read_sql_query(query.read(),conn)

  query.close()
  logging.info(f'list of meters extracted at: {datetime.datetime.now()}')

  logging.info(f'Starting Multiprocessing at: {datetime.datetime.now()}')
  pool = mp.Pool(processes=mp.cpu_count())

  logging.info(f'Data Fetch Start: {datetime.datetime.now()}')
  start = time.time()
  data = latest_meters.dropna().reset_index(drop=True)  # <----------------   lastest meters from DB // See Line 23
  data = list(data['meternumber'])

  chunks = [data[x:x + 100] for x in range(0, len(data), 100)]

  for data1 in chunks:
    pool.map(fetch_data,(i  for i in data1))

  pool.close()
  pool.join()
  logging.info(f'Multiprocessing end at: {datetime.datetime.now()}')

  end = time.time()
  logging.info(f'Data Fetch end at: {datetime.datetime.now()} Time Taken: {end - start}')
  print('Total Time Taken: ',end - start)
  logging.info(f'API Fetch Stop at: {datetime.datetime.now()} \n')
  print('done....')

