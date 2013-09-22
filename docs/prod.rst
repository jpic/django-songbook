Deploying this project
======================

This chapter covers deployment of this project.

Static files update
-------------------

When adding a new file in `songbook/static/`, you should
command django to update `songbook/public/static/`
symlinks::

    ./manage.py collectstatic -l

Database setup
--------------

Database schema update
----------------------

Database migrations are handled by south, execute them with::

    ./manage.py migrate

In case new tables were created by apps which are not managed by
south, run::

    ./manage.py syncdb

Index update
------------

If anything changed in `templates/search/indexes/`, then it would
be a good idea to re-index all data::

    ./manage.py rebuild_index

Nginx configuration
-------------------

Add this server entry to `nginx.conf`::

.. literalinclude:: examples/nginx.conf

Run `nginx -s reload` to reload nginx.

uWSGI configuration
-------------------

Create a file called `songbook.ini`. It is important
that it is called `songbook.ini` because it contains
`%n` which is a magic variable and will be replaced with `{{
project_name }}` by uWSGI. This would be a good start::

.. literalinclude:: examples/songbook.ini

Start uWSGI with an emperor on the parent directory or with `uwsgi
songbook.ini`.

..
   Local Variables:
   mode: rst
   fill-column: 79
   End:
   vim: et syn=rst tw=79
