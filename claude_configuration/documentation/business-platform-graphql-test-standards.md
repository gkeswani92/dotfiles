# GraphQL Testing Patterns Summary

Based on analyzing the existing tests in `spec/graphql/organizations/mutations/entity/` and their corresponding GraphQL query fixtures, here are the testing patterns used in this repository:

## 1. File Structure and Organization

- **Test Location**: `spec/graphql/organizations/mutations/entity/<mutation_name>_spec.rb`
- **Fixture Location**: `spec/fixtures/graphql/organizations/<mutation_name>.graphql`
- **Test files follow naming convention**: Mutation name in snake_case with `_spec.rb` suffix
- **Fixture files match test name**: Same snake_case name with `.graphql` extension

## 2. Test File Setup Pattern

```ruby
# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MutationName", with_datastores: true do
  let(:organization) { create(:organization) }
  let(:requester) { create(:organization_user, business: organization) }
  let(:requester_permissions) { %w[add_legal_entities edit_legal_entities view_legal_entities] }
  let(:permitted_sections) { [Organizations::ApiScopes::MANAGE, Organizations::ApiScopes::LEGAL_ENTITIES] }

  let(:ctx) do
    organizations_user_context(
      organization: organization,
      organization_user: requester,
      organization_user_permissions: requester_permissions,
      user: requester.user,
      permitted_sections: permitted_sections,
    )
  end

  let(:variables) { { inputName: input } }
  subject { organizations_mutation_name(variables, ctx) }

  # ... tests
end
```

**Key Elements:**

- Always marked with `with_datastores: true` (integration tests)
- Organization, requester, and permissions set up as let declarations
- Context created using `organizations_user_context` helper
- Variables use **camelCase** for GraphQL field names (matches GraphQL convention)
- Subject calls auto-generated helper method named `organizations_<mutation_name>`

## 3. Helper Methods

**Auto-generated from fixtures**: The `load_gql_to_methods` method in `spec/support/helpers/graphql_helpers.rb` automatically generates helper methods for each `.graphql` fixture file:

- Method naming pattern: `<schema>_<filename>` (e.g., `organizations_create_person`)
- These methods:
  - Load the GraphQL query from the fixture file
  - Execute it against the schema with provided variables and context
  - Return a parsed GraphQL response

**Context Helper**: `organizations_user_context` creates the execution context with:

- Current organization (`current_business`)
- Current user (`current_business_user`, `current_user`)
- Permissions via `Access::OrganizationUser::AccessControl`
- API scopes (`permitted_sections`)

## 4. GraphQL Fixture Structure

Fixtures define the complete GraphQL mutation/query with:

- All input variables typed with GraphQL types
- Return fields needed for assertions
- Nested object selections for relationships

Example:

```graphql
mutation createPerson($createPersonInput: CreatePersonInput!) {
  createPerson(createPersonInput: $createPersonInput) {
    person {
      id
      firstName
      lastName
      nameVariants {
        variantType
        firstName
        fullName
      }
    }
  }
}
```

## 5. Test Organization Patterns

Tests are organized into contexts covering:

### A. Permission Testing

```ruby
context "when the requestor does not have the correct permission" do
  let(:requester_permissions) { %w[view_legal_entities] }

  include_examples "GraphQL field is inaccessible", "mutationName"
end
```

- Uses shared example for consistent permission checking
- Tests that insufficient permissions hide the field entirely

### B. Success Scenarios

```ruby
context "when valid inputs are passed" do
  it "creates the entity" do
    expect { subject }.to(change(Entity::Model, :count).by(1))
  end

  it "returns the created entity with correct attributes", aggregate_failures: true do
    result = subject.data.mutation_name.entity
    expect(result.first_name).to eq(first_name)
    expect(result.last_name).to eq(last_name)
  end

  it "returns no user errors" do
    expect(subject.data.mutation_name.user_errors).to be_empty
  end
end
```

- Use `aggregate_failures: true` for multiple assertions in one test
- Test database changes with `change` matcher
- Verify returned GraphQL data matches expectations
- Always check `user_errors` are empty

### C. Error Scenarios

```ruby
context "when invalid inputs are passed" do
  let(:equity_ownership) { 101.00 }

  it "returns a user error" do
    expect(subject.data.mutation_name.user_errors).to contain_exactly(
      have_attributes(
        field: %w[business_attributes equity_ownership],
        message: "Equity ownership must be a valid percentage.",
      ),
    )
  end
end
```

- Override let declarations to create invalid states
- Check `user_errors` contain expected errors
- Use `have_attributes` matcher for structured error assertions

### D. Edge Cases

```ruby
context "when optional attributes are not provided" do
  let(:variables) { { createInput: {} } }

  it "creates the entity with nil values" do
    result = subject.data.mutation_name.entity
    expect(result.first_name).to be_nil
  end
end
```

## 6. Assertion Patterns

### Nested Object Assertions using `have_attributes`:

```ruby
expect(subject.data.create_principal.principal).to have_attributes(
  email: "test@example.com",
  job_title: "CEO",
  person: have_attributes(
    first_name: "John",
    last_name: "Doe",
    addresses: have_attributes(
      nodes: contain_exactly(
        have_attributes(
          address_line1: "123 Main St",
          city: "Anytown",
        ),
      ),
    ),
  ),
)
```

### Array/Collection Matchers:

```ruby
# For exact matches
expect(result.roles).to eq([...])

# For unordered matches
expect(result.nationalities.map(&:country_code)).to match_array(%w[US CA])

# For partial matches
expect(result).to contain_exactly(have_attributes(...))
```

### Database Verification (when needed):

```ruby
it "stores variants correctly in database" do
  person_external_id = subject.data.create_person.person.id
  person_id = Base64.urlsafe_decode64(person_external_id).split("/")[-1]
  person = Entity::Person.find_by(id: person_id)

  expect(person.name_variants).to eq({ "kanji" => { ... } })
end
```

## 7. Integration Test Philosophy

- **No Mocking**: Tests execute the full stack from GraphQL to database
- **Real Database Interactions**: Use factories to create test data
- **Complete Flow Testing**: Test the entire mutation including all operations
- **Scoped with `unscoped`**: For inactive records, use `Model.unscoped.find_by`

## 8. Variable Naming Conventions

- **Ruby (let declarations)**: snake_case (`first_name`, `legal_entity`)
- **GraphQL (variables hash)**: camelCase (`firstName`, `legalEntity`)
- **GraphQL IDs**: Use `Base64.urlsafe_encode64("gid://organization/ModelName/#{id}", padding: false)` or model's `.gid` method

## 9. Test Data Setup

**Factory Usage**:

```ruby
let(:legal_entity) { create(:entity_legal_entity, :company, organization: organization) }
let(:person) { create(:entity_person, :all_name_parts, organization: organization) }
```

- Use traits for common configurations (`:company`, `:individual`, `:all_name_parts`)
- Always associate with the test organization
- Create before context if multiple tests need them

## 10. Common Test Scenarios to Cover

For an upsert mutation, test:

1. **Create scenarios**: With all fields, with minimal fields, with nested objects
2. **Update scenarios**: Updating existing entity, partial updates
3. **Permissions**: Missing required permissions
4. **Validation errors**: Invalid field values, business rule violations
5. **Edge cases**: Empty arrays vs nil, archived entities, nil vs empty strings
6. **Nested operations**: Creating/updating related entities (principals, addresses, identifiers)
7. **Deletion operations**: Deleting related entities via `deleted_*_ids` fields

## 11. Response Structure Access

GraphQL responses are accessed via:

```ruby
subject.data.<mutation_name>.<field>
subject.data.<mutation_name>.user_errors
```

All field names are automatically converted to snake_case by the `GraphQLResponse` helper class.

---

This testing pattern ensures comprehensive coverage while maintaining readability and following the integration test philosophy of testing real behavior without mocking.
