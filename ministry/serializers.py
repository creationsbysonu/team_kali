"""
Ministry Serializers

Different serializers for different user roles:
- Public: Basic info only
- Member: More details for staff
- Admin: Full details including settings
"""
from rest_framework import serializers
from .models import Ministry, MinistryMember, MinistryInvitation, StaffService
from places.models import Place


class MinistryListSerializer(serializers.ModelSerializer):
    """
    Minimal serializer for ministry listing in public API.
    Shows only logo and name.
    """
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = ['id', 'name', 'slug', 'logo_url']
        read_only_fields = fields
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None


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
    place_id = serializers.SerializerMethodField()
    place_name = serializers.SerializerMethodField()
    place_slug = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = [
            'id', 'place', 'place_id', 'place_name', 'place_slug',
            'name', 'slug', 'description',
            'email', 'phone', 'address', 'website',
            'logo', 'logo_url', 'status', 'settings',
            'member_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'place_id', 'place_name', 'place_slug', 'created_at', 'updated_at']
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None
    
    def get_member_count(self, obj):
        # Use annotated value if available, otherwise query
        if hasattr(obj, 'member_count'):
            return obj.member_count
        return obj.members.filter(is_active=True).count()
    
    def get_place_id(self, obj):
        return str(obj.place.id) if obj.place else None
    
    def get_place_name(self, obj):
        return obj.place.name if obj.place else None
    
    def get_place_slug(self, obj):
        return obj.place.slug if obj.place else None


class MinistryCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new ministries (super admin only)"""
    place = serializers.PrimaryKeyRelatedField(
        queryset=Place.objects.filter(is_active=True),
        required=True,
        allow_null=False,
        help_text="UUID of the place where this ministry will be created"
    )
    name = serializers.CharField(required=True, max_length=255)
    email = serializers.EmailField(required=True)
    slug = serializers.SlugField(required=False, allow_blank=True, default='', max_length=100)
    
    class Meta:
        model = Ministry
        fields = [
            'place', 'name', 'slug', 'description',
            'email', 'phone', 'address', 'website',
            'logo', 'status', 'settings'
        ]
    
    def validate_place(self, value):
        """Ensure place exists and is active"""
        if not value:
            raise serializers.ValidationError("Place is required")
        if not value.is_active:
            raise serializers.ValidationError("Selected place is not active")
        return value
    
    def validate(self, attrs):
        from django.utils.text import slugify
        
        place = attrs.get('place')
        name = attrs.get('name')
        slug = attrs.get('slug')
        
        # Auto-generate slug from name if not provided
        if not slug and name:
            base_slug = slugify(name)
            slug = base_slug
            counter = 1
            
            # Ensure unique slug within the place
            while Ministry.objects.filter(place=place, slug=slug).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            
            attrs['slug'] = slug
        elif place and slug:
            # Check if provided slug is unique within the place
            if Ministry.objects.filter(place=place, slug=slug).exists():
                raise serializers.ValidationError({
                    "slug": "This slug is already taken for this place."
                })
        
        return attrs


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


# ==================== Staff Service Serializers ====================

class StaffServiceSerializer(serializers.ModelSerializer):
    """
    Serializer for staff service details.
    Used by ministry admin to view/manage staff services.
    Shows service info, staff info, and availability status.
    """
    service_logo_url = serializers.SerializerMethodField()
    staff_image_url = serializers.SerializerMethodField()
    ministry_name = serializers.CharField(source='ministry.name', read_only=True)
    place_name = serializers.CharField(source='ministry.place.name', read_only=True)
    is_available = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = StaffService
        fields = [
            'id', 'ministry', 'ministry_name', 'place_name',
            'service_name', 'service_logo', 'service_logo_url',
            'staff_name', 'staff_image', 'staff_image_url',
            'email', 'status', 'is_active', 'is_available',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'is_available']
        extra_kwargs = {
            'password': {'write_only': True}
        }
    
    def get_service_logo_url(self, obj):
        if obj.service_logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.service_logo.url)
            return obj.service_logo.url
        return None
    
    def get_staff_image_url(self, obj):
        if obj.staff_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.staff_image.url)
            return obj.staff_image.url
        return None


class StaffServiceCreateSerializer(serializers.Serializer):
    """
    Serializer for creating staff services.
    Ministry admin provides: service name, service logo, staff name, staff image, email, password
    """
    service_name = serializers.CharField(max_length=255)
    service_logo = serializers.ImageField(required=False, allow_null=True)
    staff_name = serializers.CharField(max_length=255)
    staff_image = serializers.ImageField(required=False, allow_null=True)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    
    def validate_email(self, value):
        """Ensure email is unique"""
        email = value.lower().strip()
        if StaffService.objects.filter(email=email).exists():
            raise serializers.ValidationError("Staff service with this email already exists")
        return email
    
    def validate_password(self, value):
        """Basic password validation"""
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long")
        return value


class StaffServiceUpdateSerializer(serializers.Serializer):
    """
    Serializer for updating staff service.
    Can update service info, staff info, and status.
    Password is updated separately via reset password endpoint.
    """
    service_name = serializers.CharField(max_length=255, required=False)
    service_logo = serializers.ImageField(required=False, allow_null=True)
    staff_name = serializers.CharField(max_length=255, required=False)
    staff_image = serializers.ImageField(required=False, allow_null=True)
    status = serializers.ChoiceField(
        choices=['active', 'paused'],
        required=False,
        help_text="Service availability status"
    )
    is_active = serializers.BooleanField(
        required=False,
        help_text="System-level enable/disable"
    )
    
    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError("At least one field must be provided")
        return attrs


class StaffServicePasswordResetSerializer(serializers.Serializer):
    """Serializer for resetting staff service password"""
    new_password = serializers.CharField(write_only=True, min_length=8)
    
    def validate_new_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long")
        return value


class StaffServiceStatusToggleSerializer(serializers.Serializer):
    """
    Serializer for toggling service status (ACTIVE/PAUSED).
    Used for quick status changes, e.g., when staff marks attendance.
    """
    status = serializers.ChoiceField(
        choices=['active', 'paused'],
        help_text="Set service status to active or paused"
    )
