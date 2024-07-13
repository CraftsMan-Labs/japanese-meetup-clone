from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, DateTimeField, SubmitField
from wtforms.validators import DataRequired, Length

class EventForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired(), Length(max=100)])
    description = TextAreaField('Description')
    date = DateTimeField('Date and Time', format='%Y-%m-%d %H:%M', validators=[DataRequired()])
    location = StringField('Location', validators=[Length(max=100)])
    submit = SubmitField('Create Event')
