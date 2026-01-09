"""
Places App - Data/Domain Layer

This app defines the Place model - representing decentralized locations.
Places are the primary entity that contains ministries.

Example: Kathmandu, Biratnagar, Pokhara, etc.

Contains:
- Place model (database structure)
- Model properties & methods
- Migrations
- Seed commands
- Admin registration

Does NOT contain:
- Views
- URLs
- Serializers
- API endpoints
- Business logic services

Other apps (like tenants/admin, public) import and use this model.
"""
