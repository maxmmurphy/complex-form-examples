require File.expand_path('../../test_helper', __FILE__)

describe "On a ProjectsController, when updating", ActionController::TestCase do
  tests ProjectsController
  
  before do
    @project = Project.create(:name => 'NestedParams')
    @project.create_author(:name => 'Eloy')
    @project.tasks.create(:name => 'Check other implementations')
    @project.tasks.create(:name => 'Try with our plugin')
    @tasks = @project.tasks
    
    @valid_update_params = { :name => 'Dinner', :tasks_attributes => [
      { :id => @tasks.first.id, :name => "Buy food" },
      { :id => @tasks.last.id,  :name => "Cook" }
    ]}
  end
  
  it "should update the name of the author" do
    put :update, :id => @project.id, :project => { :author_attributes => { :name => 'Mighty Mo' }}
    @project.reload.author.name.should == 'Mighty Mo'
  end
  
  it "should update attributes of the nested tasks" do
    put :update, :id => @project.id, :project => @valid_update_params
    @project.reload
    
    @project.name.should == 'Dinner'
    @project.tasks.map(&:name).sort.should == ['Buy food', 'Cook']
  end
  
  it "should destroy a missing task" do
    @valid_update_params[:tasks_attributes].first['_delete'] = '1'
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.differ('Task.count', -1)
  end
  
  it "should add a new task" do
    @valid_update_params[:tasks_attributes] << { :name => 'Take out' }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.differ('Task.count', +1)
  end
  
  it "should reject any new task where the name is empty" do
    @valid_update_params[:tasks_attributes] << { 'name' => '', :due_at => nil }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.not.differ('Task.count')
    
    assigns(:project).should.be.valid
  end
  
  it "should destroy a task and add a new one" do
    @valid_update_params[:tasks_attributes].first['_delete'] = '1'
    @valid_update_params[:tasks_attributes] << { :name => 'Take out' }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.not.differ('Task.count')
  end
  
  it "should not be valid if a task is invalid" do
    put :update, :id => @project.id, :project => { :name => 'Nothing', :tasks_attributes =>[
      { :id => @tasks.first.id, :name => '' },
      { :id => @tasks.last.id, :name => '' }
    ]}
    
    project = assigns(:project)
    
    project.should.not.be.valid
    project.errors.on(:tasks_name).should == "can't be blank"
    
    project.reload
    project.name.should == 'NestedParams'
  end
end