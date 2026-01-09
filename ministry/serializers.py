"""
Ministry Serializers

Different serializers for different user roles:
- Public: Basic info only
- Member: More details for staff
- Admin: Full details including settings
"""
from rest_framework import serializers
from .models import Ministry, MinistryMember, MinistryInvitation


class MinistryPublicSerializer(serializers.ModelSerializer):
    """
    Public serializer for ministry listing.
    Shows only basic public information.
    """
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = [
            'id', 'name', 'slug', 'description',
            'logo_url', 'website'
        ]
        read_only_fields = fields
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None


class MinistrySerializer(serializers.ModelSerializer):
    """
    Standard serializer for ministry members.
    Shows contact info and basic settings.
    """
    logo_url = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = [
            'id', 'name', 'slug', 'description',
            'email', 'phone', 'address', 'website',
            'logo_url', 'status', 'member_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slug', 'status', 'created_at', 'updated_at']
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None
    
    def get_member_count(self, obj):
        return obj.members.filter(is_active=True).count()


class MinistryAdminSerializer(serializers.ModelSerializer):
    """
    Full serializer for super admins.
    Includes settings and all details.
    """
    logo_url = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = [
            'id', 'name', 'slug', 'description',
            'email', 'phone', 'address', 'website',
            'logo', 'logo_url', 'status', 'settings',
            'member_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None
    
    def get_member_count(self, obj):
        return obj.members.filter(is_active=True).count()


class MinistryCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new ministries (super admin only)"""
    
    class Meta:
        model = Ministry
        fields = [
            'place', 'name', 'slug', 'description',
            'email', 'phone', 'address', 'website',
            'logo', 'status', 'settings'
        ]
    
    def validate(self, data):
        place = data.get('place')
        slug = data.get('slug')
        if place and slug:
            if Ministry.objects.filter(place=place, slug=slug).exists():
                raise serializers.ValidationError({
                    "slug": "This slug is already taken for this place."
                })
        return data


class MinistryMemberSerializer(serializers.ModelSerializer):
    """Serializer for ministry admin membership"""
    user_email = serializers.CharField(source='user.email', read_only=True)
    ministry_name = serializers.CharField(source='ministry.name', read_only=True)
    
    class Meta:
        model = MinistryMember
        fields = [
            'id', 'ministry', 'ministry_name',
            'user', 'user_email',
            'is_active',
            'joined_at', 'updated_at'
        ]
        read_only_fields = ['id', 'joined_at', 'updated_at']


class MinistryInvitationSerializer(serializers.ModelSerializer):
    """Serializer for ministry invitations"""
    ministry_name = serializers.CharField(source='ministry.name', read_only=True)
    invited_by_email = serializers.CharField(source='invited_by.email', read_only=True)
    
    class Meta:
        model = MinistryInvitation
        fields = [
            'id', 'ministry', 'ministry_name',
            'email', 'status',
            'invited_by', 'invited_by_email',
            'created_at', 'expires_at', 'accepted_at'
        ]
        read_only_fields = ['id', 'token', 'status', 'created_at', 'accepted_at']


class MinistryInvitationCreateSerializer(serializers.Serializer):
    """Serializer for creating invitations"""
    email = serializers.EmailField()
    
    def validate_email(self, value):
        return value.lower().strip()
