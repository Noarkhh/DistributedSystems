from fastapi import FastAPI
from fastapi.responses import RedirectResponse, HTMLResponse
from datetime import datetime
import requests
import os
import asyncio

app = FastAPI()

NASA_API_KEY = os.environ['NASA_API_KEY']
HOCKEY_API_KEY = os.environ['HOCKEY_API_KEY']
FOOTBALL_API_KEY = os.environ['FOOTBALL_API_KEY']


@app.get("/", response_class=HTMLResponse)
async def read_root():
    with open("index.html", 'r') as file:
        data = file.read()
    return HTMLResponse(data)


@app.get("/date")
async def redirect(date: datetime):
    location = f"/coincidence?date={date.strftime('%Y-%m-%d')}"
    return RedirectResponse(url=location)


@app.get("/coincidence", response_class=HTMLResponse)
async def coincidence(date: str):
    date_str = date
    date = datetime.strptime(date_str, "%Y-%m-%d")
    hockey_highlight_html = asyncio.ensure_future(get_hockey_highlight(date))
    football_highlight_html = asyncio.ensure_future(get_football_highlight(date))
    asteroid_data = await get_asteroid_data(date)

    dummy_html = f"""
        <html>
            <body>
                <h1>Welcome.</h1>
                <p>On {date_str} planet Earth was nearly hit by a deadly asteroid.</p>
                <p>The closest distance was {asteroid_data["distance"]} km ({asteroid_data["distance_lunar"]} lunar).</p>
                <p>It was flying above our heads with the velocity of {asteroid_data["velocity"]} km/s.</p> 
                <p>It's diameter was equivalent to {asteroid_data["diameter"]} kilometers.</p>
                <br/>
                <p>Anyway, watch this plays that happened at the same time:</p>
                {await hockey_highlight_html}
                {await football_highlight_html}
            </body>
        </html>
        """
    return HTMLResponse(dummy_html)


async def get_asteroid_data(date: datetime) -> dict[str, float]:
    url = "https://api.nasa.gov/neo/rest/v1/feed"
    params = {
        "start_date": date.strftime("%Y-%m-%d"),
        "end_date": date.strftime("%Y-%m-%d"),
        "api_key": NASA_API_KEY
    }
    headers = {
        'Content-Type': 'application/json',
    }

    response = requests.request("GET", url, headers=headers, params=params)

    if response.status_code != 200:
        return {
            "distance": 0.0,
            "distance_lunar": 0.0,
            "velocity": 0.0,
            "diameter": 0.0
        }

    response_json = response.json()

    asteroids = response_json["near_earth_objects"][date.strftime("%Y-%m-%d")]

    if len(asteroids) == 0:
        return {
            "distance": 0.0,
            "distance_lunar": 0.0,
            "velocity": 0.0,
            "diameter": 0.0
        }

    closest_asteroid = max(
        filter(lambda asteroid: asteroid["estimated_diameter"]["meters"]["estimated_diameter_max"] > 50, asteroids),
        key=lambda asteroid: asteroid["close_approach_data"][0]["miss_distance"]["kilometers"]
    )

    return {
        "distance": float(closest_asteroid["close_approach_data"][0]["miss_distance"]["kilometers"]) / 500,
        "distance_lunar": float(closest_asteroid["close_approach_data"][0]["miss_distance"]["lunar"]) / 500,
        "velocity": float(closest_asteroid["close_approach_data"][0]["relative_velocity"]["kilometers_per_second"]) * 100,
        "diameter": closest_asteroid["estimated_diameter"]["meters"]["estimated_diameter_max"]
    }


async def get_hockey_highlight(date: datetime) -> str:
    return get_highlight("hockey-highlights-api.p.rapidapi.com", HOCKEY_API_KEY, date)


async def get_football_highlight(date: datetime) -> str:
    return get_highlight("football-highlights-api.p.rapidapi.com", FOOTBALL_API_KEY, date)


def get_highlight(host: str, api_key: str, date: datetime) -> str:
    url = f"https://{host}/highlights"
    params = {"date": date.strftime("%Y-%m-%d")}

    headers = {
        "X-RapidAPI-Key": api_key,
        "X-RapidAPI-Host": host
    }

    response = requests.request("GET", url, headers=headers, params=params)

    if response.status_code != 200:
        return ""

    response_json = response.json()

    highlights = list(filter(lambda h: h["embedUrl"] != "null", response_json["data"]))

    if len(highlights) == 0:
        return ""

    highlight = highlights[0]

    highlight_title = highlight["title"]
    embed_url = highlight["embedUrl"]

    print(highlight)

    return f"""
    <div class="highlight_video">
        <h2>{highlight_title}</h2>
        <iframe width="560" height="315" src="{embed_url}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
    </div>
    """
