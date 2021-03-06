require File.expand_path('../spec_helper', __FILE__)

describe 'has_normalized_sti' do
  describe 'classes' do
    it 'should hook in to AR:Base' do
      ActiveRecord::Base.should respond_to :has_normalized_sti
    end
  end

  describe 'instances' do
    before do
      @person  = Person.new
      @royal   = Royal.new
      @peasant = Peasant.new
    end

    it 'should respond to type' do
      @person.should respond_to(:type)
    end

    it 'should have type set to the (sub)class name' do
      @person.type.should == 'Person'
      @royal.type.should  == 'Royal'
      @peasant.type.should == 'Peasant'
    end

    it 'should have an associated normal_type' do
      @person.should respond_to(:normal_type)
    end

    it 'should have the normal_type be a new record if the type does not exist yet' do
      @person.normal_type.should be_new_record
    end

    it 'should save the assocated normal_type if it was new' do
      @person.save
      @person.normal_type.should_not be_new_record
    end

    it 'should not allow a nil normal_type' do
      @person.normal_type = nil
      @person.save.should == false
      @person.should have(1).errors_on(:normal_type)
    end

    it 'should set the normal_type to an existing record' do
      PersonType.create(:type_name => 'Person')
      Person.new.type_id.should_not be_nil
      Person.new.normal_type.should_not be_new_record
    end

    it 'should return an object of the subclassed type when searched on the parent' do
      @royal.save!
      person = Person.find(@royal.id)
      person.should be_a(Royal)
    end

    it 'should allow the type to be set manual and read back' do
      @person.type = 'Royal'
      @person.type.should == 'Royal'
    end

    it 'should allow a custom type class' do
      @peasant.normal_type.should be_a(SpecialPersonType)
    end

    it 'should allow a custom foreign key' do
      @peasant.save!
      @peasant.type_id.should be_nil
      @peasant.special_type_id.should_not be_nil
    end

    it 'should store the type in a custom column' do
      @peasant.normal_type.type_name.should be_nil
      @peasant.normal_type.special_person_type.should == 'Peasant'
    end

    it 'should be the right object when found from the base' do
      @peasant.save!
      SpecialPerson.find(@peasant.id).should be_a(Peasant)
    end

    it 'should work with the options as symbols' do
      @farmer = Farmer.new
      @farmer.normal_type.should be_a(SpecialPersonType)
      @farmer.normal_type.type_name.should be_nil
      @farmer.normal_type.special_person_type.should == 'Farmer'
      @farmer.save!
      @farmer.type_id.should be_nil
      @farmer.special_type_id.should_not be_nil
      ReallySpecialPerson.find(@farmer.id).should be_a(Farmer)
    end

    it 'should error if the type class is not loaded' do
      lambda{
        class ErrPerson < ActiveRecord::Base
          has_normalized_sti :type_class_name => 'NonExistantType'
        end
      }.should raise_error(LoadError)
    end

    it 'should only return subclassed records' do
      person = Person.create!
      royal = Royal.create!

      Royal.all.count.should == 1
    end

    it 'should only return subclassed and subsubclassed' do
      person = Person.create!
      royal = Royal.create!

      class King < Royal
      end

      King.create!
      Royal.all.count.should == 2
    end

  end
end
