from django.urls import re_path
from myapp.consumers import ChatConsumer, GroupChatConsumer, EventsConsumer

websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<sender>\w+)/(?P<receiver>\w+)/$", ChatConsumer.as_asgi()),
    re_path(r"ws/group_chat/(?P<event_id>[^/]+)/$", GroupChatConsumer.as_asgi()),
    re_path(r"ws/events/(?P<username>\w+)/$", EventsConsumer.as_asgi()),
]