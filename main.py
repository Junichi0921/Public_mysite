import streamlit as st
from streamlit_calendar import calendar
import pandas as pd

st.title('薬師寺さんお疲れ様会')

st.write('日時:12月17日水曜日18時～')

# Define calendar options
calendar_options = {
"editable": False,
"selectable": True,
"headerToolbar": {
"left": "prev,next today",
"center": "title",
"right": "dayGridMonth,timeGridWeek,timeGridDay",
"locale": "ja" , "callback": False
},
"initialView": "dayGridMonth"
}

# Define events
calendar_events = [
{"id": "1", "title": "飲み会", "start": "2025-12-17T18:00:00", "end": "2025-12-17T21:00:00"},
]
# Render the calendar
calendar_component = calendar(events=calendar_events, options=calendar_options, callbacks='')
st.write(calendar_component)

st.write('# ')

"""
https://r.gnavi.co.jp/e5g1se3d0000/
"""

st.write('場所：炭火串焼きと野菜巻き 個室居酒屋吉粋 武蔵小杉店')
# 緯度経度データ
locations = pd.DataFrame({
    'lat': [35.574463],
    'lon': [139.658568]
}) # 武蔵小杉

# 地図を表示
st.map(locations, size=2, zoom=15)

"""
その他情報
"""
df = pd.DataFrame({
    '予約番号':['PL*****'],
    '来店日時':['2025年12月17日(水)　18:00'],
    '来店人数':['8人'],
    '席':['宴会席（8名様～10名様)'],
    'コース':['『吉粋コース』3時間飲み放題付き【8品5000円→4000円】'],
    '料金（1名様）':['4,000円']},index=['情報'])
df.rename(index={'0':'情報'})
st.dataframe(df.T)
