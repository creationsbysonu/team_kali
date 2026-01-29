"""
Serializers for Officials App.
"""

from rest_framework import serializers
from .models import MinistryOfficial
from ministry.models import Ministry


class MinistryOfficialSerializer(serializers.ModelSerializer):
    """Serializer for viewing ministry officials."""
    
    ministry_name = serializers.SerializerMethodField()
    
    class Meta:
        model = MinistryOfficial
        fields = [
            'id',
            'ministry',
            'ministry_name',
            'name',
            'role',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_ministry_name(self, obj):
        """Get ministry name."""
        return obj.ministry.name if obj.ministry else None


class MinistryOfficialCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating ministry officials."""
    
    class Meta:
        model = MinistryOfficial
        fields = [
            'ministry',
            'name',
            'role',
            'is_active',
        ]
    
    def validate_ministry(self, value):
        """Validate ministry is not deleted."""
        if value.is_deleted:
            raise serializers.ValidationError("Cannot create official for deleted ministry.")
        return value
    
    def validate(self, attrs):
        """Cross-field validation."""
        # Auto-fill ministry from request context if not provided
        if not attrs.get('ministry'):
            request = self.context.get('request')
            if request and hasattr(request, 'ministry') and request.ministry:
                attrs['ministry'] = request.ministry
        
        # Check if an official with same name and role already exists for this ministry
        ministry = attrs.get('ministry')
        name = attrs.get('name')
        role = attrs.get('role')
        
        if not ministry:
            raise serializers.ValidationError({
                "ministry": "Ministry is required. Ensure X-Ministry-ID header is sent."
            })
        
        if ministry and name and role:
            existing = MinistryOfficial.objects.filter(
                ministry=ministry,
                name=name,
                role=role
            ).exclude(id=self.instance.id if self.instance else None).first()
            
            if existing:
                raise serializers.ValidationError({
                    "name": f"An official with name '{name}' and role '{role}' already exists in this ministry."
                })
        
        return attrs


class MinistryOfficialUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating ministry officials."""
    
    class Meta:
        model = MinistryOfficial
        fields = [
            'name',
            'role',
            'is_active',
        ]
    
    def validate(self, attrs):
        """Cross-field validation."""
        if not self.instance:
            return attrs
        
        # Check if updated name/role conflicts with existing official
        name = attrs.get('name', self.instance.name)
        role = attrs.get('role', self.instance.role)
        
        existing = MinistryOfficial.objects.filter(
            ministry=self.instance.ministry,
            name=name,
            role=role
        ).exclude(id=self.instance.id).first()
        
        if existing:
            raise serializers.ValidationError({
                "name": f"An official with name '{name}' and role '{role}' already exists in this ministry."
            })
        
        return attrs


class MinistryOfficialListQuerySerializer(serializers.Serializer):
    """Query parameters for filtering officials list."""
    
    ministry = serializers.UUIDField(required=False, help_text="Filter by ministry ID")
    role = serializers.CharField(required=False, help_text="Filter by role")
    is_active = serializers.BooleanField(required=False, help_text="Filter by active status")
    search = serializers.CharField(required=False, help_text="Search by name")
