# nginx.config
#
# Manages the main nginx server configuration file.

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx, sls_block with context %}
{%- from tplroot ~ '/libtofs.jinja' import files_switch with context %}

{% if nginx.install_from_source %}
nginx_log_dir:
  file.directory:
    - name: /var/log/nginx
    - user: {{ nginx.server.config.user }}
    - group: {{ nginx.server.config.user }}
{% endif %}

nginx_config:
  file.managed:
    {{ sls_block(nginx.server.opts) }}
    - name: {{ nginx.lookup.conf_file }}
    - source:
{% if 'source_path' in nginx.server.config %}
      - {{ nginx.server.config.source_path }}
{% endif %}
      {{ files_switch(['nginx.conf'],
                      'nginx_config_file_managed'
          )
      }}
    - template: jinja
{% if 'source_path' not in nginx.server.config %}
    - context:
        config: {{ nginx.server.config|json(sort_keys=False) }}
{% endif %}

{% set extra_config = nginx.server.get('extra_config', {}) %}
{% for fname in  extra_config %}
{% set settings = extra_config[fname] %}
{% if 'source_path' in settings %}
{% set source_path = settings.pop('source_path') %}
{% else %}
{% set source_path = 'salt://nginx/ng/files/server.conf' %}
{% endif %}
create_extra_config_{{ fname }}:
  file.managed:
    {% if settings is mapping %}
    {{ sls_block(settings.pop('opts', {})) }}
    {% endif %}
    - name: {{ nginx.server.get('conf_include_dir', '/etc/nginx/conf.d') }}/{{ fname }}.conf
    - source: {{ source_path }}
    - template: jinja
    - makedirs: True
    - context:
        config: {{ settings|json(sort_keys=False) }}
{% endfor %}
