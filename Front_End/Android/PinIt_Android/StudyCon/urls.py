# Invitation endpoints
path("api/decline_invitation/", views.decline_invitation, name="decline_invitation"),
path("api/get_invitations/<str:username>/", views.get_invitations, name="get_invitations"),
path('api/invite_to_event/', views.invite_to_event, name='invite_to_event'), 