from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, DateTimeField, SubmitField, PasswordField
from wtforms.validators import DataRequired, Length, Email

class EventForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired(), Length(max=100)])
    description = TextAreaField('Description')
    date = DateTimeField('Date and Time', format='%Y-%m-%d %H:%M', validators=[DataRequired()])
    location = StringField('Location', validators=[Length(max=100)])
    host_email = StringField('Host Email', validators=[DataRequired(), Email()])
    host_phone = StringField('Host Phone', validators=[DataRequired(), Length(max=15)])
    sub_host_email = StringField('Sub Host Email', validators=[Email()])
    sub_host_phone = StringField('Sub Host Phone', validators=[Length(max=15)])
    subject = StringField('Subject', validators=[Length(max=100)])  # Added subject field
    submit = SubmitField('Create Event')

class RegisterForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=4, max=25)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    phone = StringField('Phone', validators=[DataRequired(), Length(max=15)])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    submit = SubmitField('Sign Up')

class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Login')
