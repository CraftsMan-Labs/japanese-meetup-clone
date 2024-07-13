#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Create project directory
mkdir meetup_clone
cd meetup_clone

# Install required packages
pip install flask flask-sqlalchemy flask-login flask-wtf

# Create project structure
mkdir -p app/templates

# Create config.py
cat > config.py << EOL
import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-secret-key'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///meetup_clone.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
EOL

# Create app/__init__.py
cat > app/__init__.py << EOL
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from config import Config

db = SQLAlchemy()
login_manager = LoginManager()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'

    from app.routes import main
    app.register_blueprint(main)

    return app
EOL

# Create app/models.py
cat > app/models.py << EOL
from app import db, login_manager
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    events = db.relationship('Event', backref='organizer', lazy='dynamic')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Event(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    date = db.Column(db.DateTime, nullable=False)
    location = db.Column(db.String(100))
    organizer_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))
EOL

# Create app/forms.py
cat > app/forms.py << EOL
from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, DateTimeField, SubmitField
from wtforms.validators import DataRequired, Length

class EventForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired(), Length(max=100)])
    description = TextAreaField('Description')
    date = DateTimeField('Date and Time', format='%Y-%m-%d %H:%M', validators=[DataRequired()])
    location = StringField('Location', validators=[Length(max=100)])
    submit = SubmitField('Create Event')
EOL

# Create app/routes.py
cat > app/routes.py << EOL
from flask import Blueprint, render_template, redirect, url_for, flash
from flask_login import login_required, current_user
from app.models import Event
from app.forms import EventForm
from app import db

main = Blueprint('main', __name__)

@main.route('/')
def home():
    events = Event.query.order_by(Event.date).all()
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
EOL

# Create templates/base.html
cat > app/templates/base.html << EOL
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Meetup Clone{% endblock %}</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.9.3/css/bulma.min.css">
    <style>
        .navbar {
            background-color: #FFB7C5;
        }
        .button.is-primary {
            background-color: #FF69B4;
        }
    </style>
</head>
<body>
    <nav class="navbar" role="navigation" aria-label="main navigation">
        <div class="navbar-brand">
            <a class="navbar-item" href="{{ url_for('main.home') }}">
                <strong>Meetup Clone</strong>
            </a>
        </div>
        <div class="navbar-menu">
            <div class="navbar-end">
                <a class="navbar-item" href="{{ url_for('main.home') }}">Home</a>
                <a class="navbar-item" href="{{ url_for('main.create_event') }}">Create Event</a>
            </div>
        </div>
    </nav>

    <section class="section">
        <div class="container">
            {% block content %}{% endblock %}
        </div>
    </section>
</body>
</html>
EOL

# Create templates/home.html
cat > app/templates/home.html << EOL
{% extends "base.html" %}

{% block content %}
<h1 class="title">イベントを探す</h1>
<div class="columns is-multiline">
    {% for event in events %}
    <div class="column is-one-third">
        <div class="card">
            <div class="card-content">
                <p class="title is-4">{{ event.title }}</p>
                <p class="subtitle is-6">{{ event.date.strftime('%Y年%m月%d日 %H:%M') }}</p>
                <p>{{ event.location }}</p>
            </div>
            <footer class="card-footer">
                <a href="{{ url_for('main.event_details', event_id=event.id) }}" class="card-footer-item">詳細を見る</a>
            </footer>
        </div>
    </div>
    {% endfor %}
</div>
{% endblock %}
EOL

# Create templates/create_event.html
cat > app/templates/create_event.html << EOL
{% extends "base.html" %}

{% block content %}
<h1 class="title">イベントを作成</h1>
<form method="POST">
    {{ form.hidden_tag() }}
    <div class="field">
        {{ form.title.label(class="label") }}
        <div class="control">
            {{ form.title(class="input") }}
        </div>
    </div>
    <div class="field">
        {{ form.description.label(class="label") }}
        <div class="control">
            {{ form.description(class="textarea") }}
        </div>
    </div>
    <div class="field">
        {{ form.date.label(class="label") }}
        <div class="control">
            {{ form.date(class="input") }}
        </div>
    </div>
    <div class="field">
        {{ form.location.label(class="label") }}
        <div class="control">
            {{ form.location(class="input") }}
        </div>
    </div>
    <div class="field">
        <div class="control">
            {{ form.submit(class="button is-primary") }}
        </div>
    </div>
</form>
{% endblock %}
EOL

# Create templates/event_details.html
cat > app/templates/event_details.html << EOL
{% extends "base.html" %}

{% block content %}
<h1 class="title">{{ event.title }}</h1>
<p class="subtitle">{{ event.date.strftime('%Y年%m月%d日 %H:%M') }}</p>
<p><strong>場所:</strong> {{ event.location }}</p>
<p><strong>主催者:</strong> {{ event.organizer.username }}</p>
<div class="content">
    {{ event.description }}
</div>
{% endblock %}
EOL

# Create run.py
cat > run.py << EOL
from app import create_app, db

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)
EOL

echo "Meetup Clone project setup complete!"
echo "To run the application:"
echo "1. Activate the virtual environment: source venv/bin/activate"
echo "2. Run the application: python run.py"