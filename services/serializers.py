"""
Service Serializers

Serializers for public service listing and details.
"""
from rest_framework import serializers
from .models import Service, ServiceCategory


class ServicePublicMinistrySerializer(serializers.Serializer):
    """Nested ministry info for service listings"""
    id = serializers.UUIDField(read_only=True)
    name = serializers.CharField(read_only=True)
    slug = serializers.SlugField(read_only=True)
    logo_url = serializers.SerializerMethodField()
    
    def get_logo_url(self, obj):
        """Build absolute URL for ministry logo"""
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None


class ServicePublicListSerializer(serializers.ModelSerializer):
    """
    Public serializer for service listing.
    Includes ministry name and logo for frontend display.
    """
    ministry = ServicePublicMinistrySerializer(read_only=True)
    
    class Meta:
        model = Service
        fields = [
            'id',
            'name',
            'slug',
            'short_description',
            'service_type',
            'processing_time',
            'fee_amount',
            'icon',
            'is_featured',
            'ministry',  # Include ministry details
        ]
        read_only_fields = fields


class ServicePublicDetailSerializer(serializers.ModelSerializer):
    """
    Public serializer for service detail page.
    Includes full service information with ministry details.
    """
    ministry = ServicePublicMinistrySerializer(read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = Service
        fields = [
            'id',
            'name',
            'slug',
            'short_description',
            'description',
            'service_type',
            'processing_time',
            'fee_amount',
            'fee_description',
            'required_documents',
            'eligibility_criteria',
            'external_url',
            'icon',
            'is_featured',
            'ministry',
            'category_name',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields


class ServiceCategoryPublicSerializer(serializers.ModelSerializer):
    """Public serializer for service categories"""
    service_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = ServiceCategory
        fields = [
            'id',
            'name',
            'slug',
            'description',
            'icon',
            'service_count',
        ]
        read_only_fields = fields
