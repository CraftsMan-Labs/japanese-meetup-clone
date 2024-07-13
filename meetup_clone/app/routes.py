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

@main.route('/create_event', methods=['GET', 'POST'])
@login_required
def create_event():
    form = EventForm()
    if form.validate_on_submit():
        event = Event(title=form.title.data,
                      description=form.description.data,
                      date=form.date.data,
                      location=form.location.data,
                      host_email=form.host_email.data,
                      host_phone=form.host_phone.data,
                      sub_host_email=form.sub_host_email.data,
                      sub_host_phone=form.sub_host_phone.data,
                      subject=form.subject.data,
                      organizer=current_user)
        db.session.add(event)
        db.session.commit()
        flash('Event created successfully!', 'success')
        return redirect(url_for('main.home'))
    return render_template('create_event.html', form=form)

@main.route('/event/<int:event_id>')
def event_details(event_id):
    event = Event.query.get_or_404(event_id)
    return render_template('event_details.html', event=event)
