"""
R2 Storage Backend for Cloudflare R2
"""
from storages.backends.s3boto3 import S3Boto3Storage
from django.conf import settings


class R2Storage(S3Boto3Storage):
    bucket_name = getattr(settings, 'AWS_STORAGE_BUCKET_NAME', 'pinit-images')
    custom_domain = 'pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev'
    file_overwrite = False
    default_acl = 'public-read'
    querystring_auth = False
