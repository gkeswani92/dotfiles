# Business Platform RSpec Test Standards

This document outlines the testing patterns and standards used in the Business Platform codebase, derived from analysis of `spec/operations/organization_management/entity/transfer/` test files.

## 1. Factory Usage Patterns

### Factory Traits Observed

- `:equity_owner` - Creates principals with equity ownership role
- `:for_person` - Creates government identifiers associated with a person
- `:for_legal_entity` - Creates government identifiers associated with a legal entity
- `:with_attachments` - Creates supporting documents with attachments
- `:attached_content` - Creates attached file content
- `:unspecified` - Creates entities with unspecified/default states

### Factory Calling Patterns

```ruby
# Direct creation with traits
create(:principal, :equity_owner, legal_entity: source_legal_entity)

# Chained trait usage
create(:supporting_document, :with_attachments, :attached_content, documentable: person)

# Building relationships in let blocks
let(:source_principal) { create(:principal, legal_entity: source_legal_entity, person: source_person) }
```

**Key Pattern:** Factories are always created with explicit relationship associations passed as parameters, never relying on factory defaults for critical relationships.

## 2. Test Organization Structure

### File Structure

```ruby
RSpec.describe OperationName, with_datastores: true do
  # Let blocks (extensive setup, 50-100 lines)
  let(:organization) { create(:business) }
  let(:requester) { create(:business_user, organization: organization) }

  # Subject definition
  subject(:operation) { described_class.new(...params) }

  # Before blocks for instantiation
  before do
    source_person
    target_legal_entity
    # Reference all lets that need to exist
  end

  # Nested contexts for scenarios
  context "when full copy is performed" do
    # Tests
  end

  context "when shallow copy is performed" do
    # Tests
  end
end
```

### Key Patterns

- Always use `with_datastores: true` in top-level describe
- Let blocks ordered by dependency: base objects first, then composed objects
- Comments in let blocks explaining requirements: `# Must match for finding`
- Before blocks that reference all lets to trigger instantiation
- Contexts nested by scenario/behavior, not by resource type

## 3. Let, Before, and Subject Blocks

### Let Block Patterns

```ruby
# Simple lets for base objects
let(:organization) { create(:business) }
let(:requester) { create(:business_user, organization: organization) }

# Chained lets for relationships
let(:source_person) { create(:person, organization: organization) }
let(:source_principal) { create(:principal, person: source_person, legal_entity: source_legal_entity) }

# Lets with inline comments explaining test setup
let(:matching_gov_id) do
  # Must match: same type, value, country_code
  create(:government_identifier, :for_legal_entity,
    identifiable: target_legal_entity,
    identifier_type: "ein",
    value: "12-3456789"
  )
end

# Array building lets
let(:source_principals) { [source_principal_1, source_principal_2] }
```

### Before Block Pattern

```ruby
before do
  # Reference all lets that need to be instantiated
  source_person
  source_legal_entity
  source_principals
  target_legal_entity
  # This ensures records exist before operation runs
end
```

### Subject Pattern

```ruby
subject(:operation) do
  described_class.new(
    organization: organization,
    requester: requester,
    source_legal_entity_id: source_legal_entity.id,
    target_organization_id: target_organization.id,
  )
end
```

**Key Insight:** Never use `subject(:result) { operation.call }` - always define subject as operation instance, then call it explicitly in tests.

## 4. When to Use aggregate_failures

### Use aggregate_failures when:

```ruby
it "copies all entity attributes correctly", aggregate_failures: true do
  result = operation.call
  copied_entity = result[:legal_entity]

  # Multiple related expectations about the same object
  expect(copied_entity.legal_name).to eq(source_entity.legal_name)
  expect(copied_entity.trade_name).to eq(source_entity.trade_name)
  expect(copied_entity.country_code).to eq(source_entity.country_code)
  expect(copied_entity.phone_number).to eq(source_entity.phone_number)
end
```

### Don't use aggregate_failures when:

```ruby
it "creates correct number of records" do
  # Single change expectation
  expect { operation.call }.to change { Person.count }.by(1)
end

it "returns success result" do
  # Single result check
  result = operation.call
  expect(result[:user_errors]).to be_empty
end
```

**Rule:** Use `aggregate_failures: true` when testing multiple attributes/expectations about the same object state in a single test. Don't use for single assertions or change expectations.

## 5. Spec Formatting Conventions

### Test Description Format

```ruby
# Good - behavior focused, present tense
it "copies person with all attributes"
it "creates principal with correct roles"
it "returns error when person not found"

# Context descriptions - "when/with" format
context "when person has address"
context "with multiple principals"
context "when government identifier already exists"
```

### Expectation Organization

```ruby
# Pattern 1: Change expectations first
it "creates new records" do
  expect { operation.call }
    .to change { Person.count }.by(1)
    .and change { Principal.count }.by(1)
end

# Pattern 2: Result assignment, then expectations
it "returns copied entity" do
  result = operation.call

  expect(result[:legal_entity]).to be_present
  expect(result[:user_errors]).to be_empty
end

# Pattern 3: Multiple objects - use aggregate_failures
it "copies all nested entities", aggregate_failures: true do
  result = operation.call
  copied = result[:legal_entity]

  expect(copied.principals.count).to eq(2)
  expect(copied.addresses.count).to eq(1)
  expect(copied.government_identifiers.count).to eq(1)
end
```

## 6. Mocking and Stubbing Approaches

### Instance Double Pattern

```ruby
# Create mock object
let(:find_existing_operation) { instance_double(FindExistingEntitiesInTargetOrganization) }

# Stub initialization
before do
  allow(FindExistingEntitiesInTargetOrganization)
    .to receive(:new)
    .with(
      organization: target_organization,
      requester: requester,
      source_legal_entity_id: source_legal_entity.id,
    )
    .and_return(find_existing_operation)
end

# Stub method call with return value
before do
  allow(find_existing_operation)
    .to receive(:call)
    .and_return({
      legal_entity: existing_legal_entity,
      person_mapping: {},
    })
end

# Verify method was called
it "calls the find operation" do
  operation.call
  expect(find_existing_operation).to have_received(:call).once
end

# Verify method was NOT called
it "skips the find operation when flag disabled" do
  operation.call
  expect(find_existing_operation).not_to have_received(:call)
end
```

### Feature Flag Stubbing

```ruby
before do
  allow(Verdict::Flag).to receive(:enabled?).and_call_original
  allow(Verdict::Flag)
    .to receive(:enabled?)
    .with(:entity_transfer_find_existing)
    .and_return(false)
end
```

### Error Scenario Testing

```ruby
before do
  allow(copy_operation).to receive(:call).and_raise(StandardError.new("Test error"))
end

it "handles errors gracefully" do
  result = operation.call
  expect(result[:user_errors]).to be_present
end
```

## 7. Expectation Matchers

### Equality Matchers

```ruby
# Simple equality
expect(result[:legal_entity]).to eq(expected_entity)
expect(copied.legal_name).to eq(source.legal_name)

# Boolean checks
expect(result[:user_errors]).to be_empty
expect(result[:legal_entity]).to be_present
expect(result[:legal_entity]).to be_nil

# Key presence
expect(result).to have_key(:legal_entity)
expect(result).not_to have_key(:person_mapping)
```

### Collection Matchers

```ruby
# Exact array matching (order independent)
expect(copied.principals).to contain_exactly(principal_1, principal_2)

# Array size
expect(copied.principals.count).to eq(2)

# Empty checks
expect(result[:user_errors]).to be_empty
expect(copied.addresses).to be_present
```

### Attribute Matchers

```ruby
# Single object attributes
expect(copied_person).to have_attributes(
  first_name: source_person.first_name,
  last_name: source_person.last_name,
  date_of_birth: source_person.date_of_birth,
)

# Collection with object attributes
expect(copied.principals).to contain_exactly(
  an_object_having_attributes(
    job_title: "CEO",
    equity_ownership: 50.0,
  ),
  an_object_having_attributes(
    job_title: "CFO",
    equity_ownership: 25.0,
  ),
)
```

### Change Matchers

```ruby
# Single change
expect { operation.call }.to change { Person.count }.by(1)

# Multiple changes
expect { operation.call }
  .to change { Person.count }.by(1)
  .and change { Principal.count }.by(2)
  .and change { Address.count }.by(1)

# No change
expect { operation.call }.not_to change { Person.count }
```

### Nested Attribute Checking

```ruby
# Access nested objects, then check attributes separately
it "copies address correctly", aggregate_failures: true do
  result = operation.call
  copied_address = result[:legal_entity].addresses.first

  expect(copied_address.address_line_1).to eq(source_address.address_line_1)
  expect(copied_address.city).to eq(source_address.city)
  expect(copied_address.country_code).to eq(source_address.country_code)
end
```

## 8. Edge Cases and Error Testing

### Common Edge Cases Tested

```ruby
context "when person has no address" do
  let(:source_person) { create(:person, organization: organization) }
  # No address created

  it "copies person without address" do
    result = operation.call
    expect(result[:person].addresses).to be_empty
  end
end

context "when government identifiers array is empty" do
  it "returns empty person_mapping" do
    result = operation.call
    expect(result).not_to have_key(:person_mapping)
  end
end

context "when identifier type differs" do
  let(:target_gov_id) { create(:government_identifier, identifier_type: "ssn") }

  it "does not match" do
    result = operation.call
    expect(result).not_to have_key(:person)
  end
end
```

### Error Scenarios

```ruby
context "when requester lacks access" do
  let(:requester) { create(:business_user) } # Different organization

  it "returns access error" do
    result = operation.call
    expect(result[:user_errors]).to be_present
    expect(result[:legal_entity]).to be_nil
  end
end

context "when operation raises error" do
  before do
    allow(operation).to receive(:call).and_raise(StandardError)
  end

  it "handles error gracefully" do
    expect { operation.call }.not_to raise_error
  end
end
```

---

## Key Takeaways for Writing Tests

1. **Always use `with_datastores: true`** in describe block
2. **Extensive let blocks** for setup, ordered by dependency
3. **Before blocks** to instantiate all necessary lets
4. **Subject as operation instance**, not result
5. **aggregate_failures** only for multiple related assertions about same object
6. **Clear test descriptions** in present tense, behavior-focused
7. **Mock with instance_double** and verify with have_received
8. **Test edge cases** (nil, empty arrays, mismatches)
9. **Test error scenarios** (access denied, validation failures)
10. **Use appropriate matchers**: contain_exactly for arrays, have_attributes for objects, change for record creation
