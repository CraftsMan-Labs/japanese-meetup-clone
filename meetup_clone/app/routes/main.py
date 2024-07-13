from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from app.models import Event
from app.forms import EventForm
from app import db
from datetime import datetime
import random

main = Blueprint('main', __name__)

@main.route('/')
def home():
    location = request.args.get('location')
    date = request.args.get('date', datetime.now().strftime('%Y-%m-%d'))
    date = datetime.strptime(date, '%Y-%m-%d')

    if location:
        events = Event.query.filter(Event.location == location, Event.date >= date).order_by(Event.date).all()
    else:
        events = Event.query.filter(Event.date >= date).order_by(Event.date).all()
        if len(events) > 10:
            events = random.sample(events, 10)

    return render_template('home.html', events=events)
