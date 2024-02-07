{#
params:
- selected_qvalue
- option_class
#}
{% for name,p in m.predicate %}
    <li class="{% if p.id == selected_qvalue %}active{% endif %}">
        <a href="#" class="dropdown-item {{ option_class }}" data-value="{{ p.id }}">{{ p.title|default:p.name }}</a>
    </li>
{% endfor %}
