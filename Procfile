web: python manage.py migrate --noinput && python manage.py collectstatic --noinput && gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:$PORT
