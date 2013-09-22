#!/usr/bin/env bash
touch /tmp/installscript
chmod +x /tmp/installscript

function install_os {
    apt-get update
    
    cat > /etc/rc.local <<EOF
#!/usr/bin/env bash
dhclient eth0
uwsgi /etc/uwsgi/apps-enabled/songbook.ini
exit 0
EOF
    
    cat >> /home/vagrant/.bashrc <<EOF
export DJANGO_SETTINGS_MODULE=songbook.settings.vagrant
cd /vagrant
source env/bin/activate 

echo 'Server reload: kill -HUP \$(</tmp/uwsgi_songbook.pid)'
echo 'Server stop: kill -INT \$(</tmp/uwsgi_songbook.pid)'
echo 'Server start: uwsgi /etc/uwsgi/apps-enabled/songbook.ini'
echo Server logs: tail -f /vagrant/uwsgi.log
echo
if [[ -f /tmp/uwsgi_songbook.pid ]]; then
    kill -0 \$(</tmp/uwsgi_songbook.pid)

    if [[ \$? -eq 0 ]]; then
        echo Server is currently running
    else
        echo Server is dead, starting server
    fi
else
    echo Server is **not** running, starting
    uwsgi /etc/uwsgi/apps-enabled/songbook.ini
fi
EOF
}

function install_db {
    sudo apt-get install -y postgresql-9.1

    cat > /tmp/installscript <<EOF
#!/usr/bin/env bash
psql -f /vagrant/docs/examples/postgresql_utf8_template.sql
createuser -wsrd vagrant
createdb -E UTF8 -O vagrant django
EOF
    su postgres -c /tmp/installscript
        
    cat > /tmp/installscript <<EOF
export DJANGO_SETTINGS_MODULE=songbook.settings.vagrant
source /srv/songbook/env/bin/activate
cd /srv/songbook
./manage.py syncdb --noinput
./manage.py migrate
EOF
    su vagrant -c /tmp/installscript
}

function install_http {
    apt-get install -y nginx uwsgi uwsgi-plugin-python nodejs npm memcached
    npm install -g coffee-script recess

    ln -sfn /vagrant/docs/examples/nginx.conf /etc/nginx/nginx.conf
    /etc/init.d/nginx start
    
    ln -sfn /vagrant/docs/examples/songbook.ini /etc/uwsgi/apps-enabled/
    
    cat > /tmp/installscript <<EOF
export DJANGO_SETTINGS_MODULE=songbook.settings.vagrant
source /srv/songbook/env/bin/activate
cd /srv/songbook
./manage.py collectstatic -l --noinput
EOF
    su vagrant -c /tmp/installscript
    
    uwsgi /etc/uwsgi/apps-enabled/songbook.ini
}

function install_project {
    echo DJANGO_SETTINGS_MODULE=songbook.settings.vagrant >> /etc/bash.bashrc
    
    apt-get install -y git python-virtualenv python-imaging python-psycopg2 python-pylibmc

    ln -sfn /vagrant /srv/songbook
    chown vagrant /srv/songbook

    cat > /tmp/installscript <<EOF
#!/usr/bin/env bash
virtualenv --system-site-packages /srv/songbook/env
source /srv/songbook/env/bin/activate
pip install django
pip install -r /srv/songbook/requirements/base.txt
EOF
    su vagrant -c /tmp/installscript
}

install_os
install_project
install_db
install_http
