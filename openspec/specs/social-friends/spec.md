# social-friends Specification

## Purpose
TBD - created by archiving change develop-game-dashboard-and-social-management. Update Purpose after archive.
## Requirements
### Requirement: Player Discovery For Friends
The system SHALL allow authenticated users to discover other players using privacy-safe public profile fields.

#### Scenario: User searches by username
- **WHEN** an authenticated user searches for another player's username
- **THEN** the server returns matching public profiles without exposing private fields such as email, refresh tokens, or internal moderation metadata

#### Scenario: User searches for self
- **WHEN** an authenticated user searches for their own profile in friend discovery
- **THEN** the client SHALL NOT offer a friend-request action for that profile

### Requirement: Friend Request Lifecycle
The system SHALL support sending, cancelling, accepting, rejecting, and listing friend requests between authenticated users.

#### Scenario: User sends friend request
- **WHEN** user A sends a friend request to user B and no pending request or friendship already exists
- **THEN** the server creates a pending friend request visible to both users with appropriate direction/status

#### Scenario: User accepts friend request
- **WHEN** user B accepts a pending request from user A
- **THEN** the server marks the request accepted, creates a friendship between A and B, and both users see each other in friend lists

#### Scenario: User rejects friend request
- **WHEN** user B rejects a pending request from user A
- **THEN** the server marks the request rejected and does not create a friendship

#### Scenario: User cancels outgoing request
- **WHEN** user A cancels a pending outgoing request to user B
- **THEN** the server marks the request cancelled and user B no longer sees it as actionable

### Requirement: Duplicate And Self Relationship Prevention
The system SHALL prevent self-friend requests, duplicate pending requests, and duplicate friendships even under concurrent requests.

#### Scenario: Self friend request rejected
- **WHEN** a user sends a friend request to their own user ID
- **THEN** the server rejects the request with a machine-readable validation error and creates no request

#### Scenario: Duplicate pending request rejected
- **WHEN** a pending friend request already exists between two users
- **THEN** another request between the same two users is rejected or treated idempotently without creating a duplicate

#### Scenario: Duplicate friendship rejected
- **WHEN** two users are already friends
- **THEN** any new friend request between them is rejected or treated idempotently without creating another friendship record

### Requirement: Friend List And Removal
The system SHALL allow authenticated users to list and remove their friendships.

#### Scenario: User lists friends
- **WHEN** an authenticated user opens their friends list
- **THEN** the server returns that user's friends with public profile summaries and relationship metadata

#### Scenario: User removes friend
- **WHEN** an authenticated user removes an existing friend
- **THEN** the friendship is removed for both users and neither user appears in the other's friend list

#### Scenario: User removes non-friend
- **WHEN** an authenticated user attempts to remove a user who is not their friend
- **THEN** the server returns a not-found or no-op response without changing other relationships

### Requirement: Friend Privacy And Authorization
The system SHALL enforce ownership and privacy checks for all friend request and friend list operations.

#### Scenario: User reads own requests
- **WHEN** an authenticated user requests incoming or outgoing friend requests
- **THEN** the server returns only requests where that user is requester or recipient

#### Scenario: User attempts to modify another user's request
- **WHEN** a user attempts to accept, reject, cancel, or remove a relationship they do not own
- **THEN** the server rejects the operation with an authorization error and leaves the relationship unchanged

### Requirement: Friend Game Integration
The system SHALL expose friend relationship state to dashboard/gameplay entry points without coupling friend APIs directly to WebSocket room internals.

#### Scenario: User opens a friend's profile
- **WHEN** an authenticated user views a friend's profile
- **THEN** the client can show friend status and available game actions such as inviting to a room if invite support is enabled

#### Scenario: Friend invite integration unavailable
- **WHEN** room invite delivery is not yet enabled
- **THEN** the dashboard still supports friend list and relationship lifecycle without failing gameplay or WebSocket flows

