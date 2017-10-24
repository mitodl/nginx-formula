# nginx.ng.config
#
# Manages the main nginx server configuration file.

{% from 'nginx/ng/map.jinja' import nginx, sls_block with context %}

{% if nginx.install_from_source %}
nginx_log_dir:
  file.directory:
    - name: /var/log/nginx
    - user: {{ nginx.server.config.user }}
    - group: {{ nginx.server.config.user }}
{% endif %}

{% if 'source_path' in nginx.server.config %}
{% set source_path = nginx.server.config.source_path %}
{% else %}
{% set source_path = 'salt://nginx/ng/files/nginx.conf' %}
{% endif %}
nginx_config:
  file.managed:
    {{ sls_block(nginx.server.opts) }}
    - name: {{ nginx.lookup.conf_file }}
    - source: {{ source_path }}
    - template: jinja
{% if 'source_path' not in nginx.server.config %}
    - context:
        config: {{ nginx.server.config|json(sort_keys=False) }}
{% endif %}

{% for fname, settings in nginx.server.get('extra_config', {}).items() %}
create_extra_config_{{ fname }}:
  file.managed:
    {{ sls_block(settings.pop('opts', {})) }}
    - name: {{ nginx.server.get('conf_include_dir', '/etc/nginx/conf.d') }}/{{ fname }}.conf
    - source: salt://nginx/ng/files/nginx.conf
    - template: jinja
    - makedirs: True
    - context:
        config: {{ settings|json(sort_keys=False) }}
{% endfor %}
