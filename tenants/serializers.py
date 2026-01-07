"""
Tenant Serializers

Different serializers for different user roles:
- Public: Basic info only
- Member: More details for staff
- Admin: Full details including settings
"""
from rest_framework import serializers
from .models import Tenant, TenantMember, TenantInvitation


class TenantPublicSerializer(serializers.ModelSerializer):
    """
    Public serializer for tenant listing.
    Shows only basic public information.
    """
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Tenant
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


class TenantSerializer(serializers.ModelSerializer):
    """
    Standard serializer for tenant members.
    Shows contact info and basic settings.
    """
    logo_url = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Tenant
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


class TenantAdminSerializer(serializers.ModelSerializer):
    """
    Full serializer for super admins.
    Includes settings and all details.
    """
    logo_url = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Tenant
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


class TenantCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new tenants (super admin only)"""
    
    class Meta:
        model = Tenant
        fields = [
            'name', 'slug', 'description',
            'email', 'phone', 'address', 'website',
            'logo', 'status', 'settings'
        ]
    
    def validate_slug(self, value):
        if Tenant.objects.filter(slug=value).exists():
            raise serializers.ValidationError("This slug is already taken.")
        return value


class TenantMemberSerializer(serializers.ModelSerializer):
    """Serializer for ministry staff membership"""
    user_email = serializers.CharField(source='user.email', read_only=True)
    tenant_name = serializers.CharField(source='tenant.name', read_only=True)
    
    class Meta:
        model = TenantMember
        fields = [
            'id', 'tenant', 'tenant_name',
            'user', 'user_email',
            'is_active',
            'joined_at', 'updated_at'
        ]
        read_only_fields = ['id', 'joined_at', 'updated_at']


class TenantInvitationSerializer(serializers.ModelSerializer):
    """Serializer for ministry invitations"""
    tenant_name = serializers.CharField(source='tenant.name', read_only=True)
    invited_by_email = serializers.CharField(source='invited_by.email', read_only=True)
    
    class Meta:
        model = TenantInvitation
        fields = [
            'id', 'tenant', 'tenant_name',
            'email', 'status',
            'invited_by', 'invited_by_email',
            'created_at', 'expires_at', 'accepted_at'
        ]
        read_only_fields = ['id', 'token', 'status', 'created_at', 'accepted_at']


class TenantInvitationCreateSerializer(serializers.Serializer):
    """Serializer for creating invitations"""
    email = serializers.EmailField()
    
    def validate_email(self, value):
        return value.lower().strip()
