{% extends "admin_edit_widget_std.tpl" %}

{% block widget_title %}
{_ Export _}
<div class="widget-header-tools">
    <a href="javascript:void(0)" class="z-btn-help do_dialog" data-dialog="title: '{{ _"Help about export"|escapejs }}', text: '{{ _"Download this page or the query as a spreadsheet or in another format."|escapejs }}'" title="{_ Need more help? _}"></a>
</div>
{% endblock %}

{% block widget_show_minimized %}true{% endblock %}
{% block widget_id %}admin_export_sidebar{% endblock %}

{% block widget_content %}
<div class="form-group">
    {% if id.is_a.query %}
        <p>{_ Download all the pages matching the query _}</p>
        <a class="btn btn-default" href="{% url export_rsc_query type='csv' id=id %}">{_ Download CSV _}</a>
        <a class="btn btn-default" href="{% url export_rsc_query type='xlsx' id=id %}">{_ Download Excel _}</a>
        <a class="btn btn-default" href="{% url export_rsc_query type='vevent' id=id %}">{_ Download Event _}</a>
    {% elseif id.is_a.collection %}
        <p>{_ Download all the pages in the collection _}</p>
        <a class="btn btn-default" href="{% url export_rsc_query type='csv' id=id %}">{_ Download CSV _}</a>
        <a class="btn btn-default" href="{% url export_rsc_query type='xlsx' id=id %}">{_ Download Excel _}</a>
        <a class="btn btn-default" href="{% url export_rsc_query type='vevent' id=id %}">{_ Download Event _}</a>
    {% elseif id.is_a.event %}
        <a class="btn btn-default" href="{% url export_rsc type='vevent' id=id %}">{_ Download Event _}</a>
        <a class="btn btn-default" href="{% url export_rsc type='csv' id=id %}">{_ Download CSV _}</a>
        <a class="btn btn-default" href="{% url export_rsc type='xlsx' id=id %}">{_ Download Excel _}</a>
    {% else %}
        <a class="btn btn-default" href="{% url export_rsc type='csv' id=id %}">{_ Download CSV _}</a>
        <a class="btn btn-default" href="{% url export_rsc type='xlsx' id=id %}">{_ Download Excel _}</a>
    {% endif %}
</div>
{% endblock %}
