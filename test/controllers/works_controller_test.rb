require "test_helper"

describe WorksController do
  let(:existing_work) { works(:album) }
  let(:user_one) { users(:dan) }
  let(:user_two) { users(:kari) }

  describe "root" do
    it "succeeds with all media types" do
      get root_path

      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      only_book = works(:poodr)
      only_book.destroy

      get root_path

      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.all do |work|
        work.destroy
      end

      get root_path

      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    describe "logged in user" do
      before do
        perform_login(user_two)
      end
      it "succeeds when there are works" do
        # perform_login(user_one)
        get works_path

        must_respond_with :success
      end

      it "succeeds when there are no works" do
        # perform_login(user_one)
        Work.all do |work|
          work.destroy
        end

        get works_path

        must_respond_with :success
      end
    end

    describe "guest user" do
      it "will flash error message and redirect if user is not logged in" do
        get works_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "You must be logged in to see this page!"
        must_redirect_to root_path
      end
    end
  end

  describe "new" do
    describe "logged in user" do
      before do
        perform_login(user_one)
      end
      it "succeeds" do
        # perform_login(user_one)
        get new_work_path

        must_respond_with :success
      end
    end

    describe "guest user" do
      it "will flash error message and redirect if user is not logged in" do
        get new_work_path
        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "You must be logged in to see this page!"
        must_redirect_to root_path
      end
    end
  end

  describe "create" do
    describe "logged in user" do
      before do
        perform_login(user_two)
      end
      it "creates a work with valid data for a real category" do
        # perform_login(user_one)
        new_work = { work: { title: "Dirty Computer", category: "album" } }

        expect {
          post works_path, params: new_work
        }.must_change "Work.count", 1

        new_work_id = Work.find_by(title: "Dirty Computer").id

        must_respond_with :redirect
        must_redirect_to work_path(new_work_id)
      end

      it "renders bad_request and does not update the DB for bogus data" do
        # perform_login(user_one)
        bad_work = { work: { title: nil, category: "book" } }

        expect {
          post works_path, params: bad_work
        }.wont_change "Work.count"

        must_respond_with :bad_request
      end

      it "renders 400 bad_request for bogus categories" do
        # perform_login(user_one)
        INVALID_CATEGORIES.each do |category|
          invalid_work = { work: { title: "Invalid Work", category: category } }

          proc { post works_path, params: invalid_work }.wont_change "Work.count"

          Work.find_by(title: "Invalid Work", category: category).must_be_nil
          must_respond_with :bad_request
        end
      end
    end

    describe "guest user" do
      it "will flash error message and redirect if user is not logged in" do
        new_work = { work: { title: "Dirty Computer", category: "album" } }
        post works_path, params: new_work

        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "You must be logged in to see this page!"
        must_redirect_to root_path
      end
    end
  end

  describe "show" do
    describe "logged in user" do
      before do
        perform_login(user_one)
      end
      it "succeeds for an extant work ID" do
        get work_path(existing_work.id)

        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        destroyed_id = existing_work.id
        existing_work.destroy

        get work_path(destroyed_id)

        must_respond_with :not_found
      end
    end

    describe "guest user" do
      it "will flash error message and redirect if user is not logged in" do
        get work_path(existing_work.id)

        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "You must be logged in to see this page!"
        must_redirect_to root_path
      end
    end
  end

  describe "edit" do
    describe "logged in user" do
      before do
        perform_login(user_two)
      end
      it "succeeds for an extant work ID" do
        get edit_work_path(existing_work.id)

        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_id = existing_work.id
        existing_work.destroy

        get edit_work_path(bogus_id)

        must_respond_with :not_found
      end
    end

    describe "guest user" do
      it "will flash error message and redirect if user is not logged in" do
        get edit_work_path(existing_work.id)

        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "You must be logged in to see this page!"
        must_redirect_to root_path
      end
    end
  end

  describe "update" do
    describe "logged in user" do
      before do
        new_user = User.new(uid: 999, provider: "github", username: "angela", email: "test@test.com")
        perform_login(new_user)
      end
      it "succeeds for valid data and an extant work ID" do
        updates = { work: { title: "Dirty Computer" } }

        expect {
          put work_path(existing_work), params: updates
        }.wont_change "Work.count"
        updated_work = Work.find_by(id: existing_work.id)

        updated_work.title.must_equal "Dirty Computer"
        must_respond_with :redirect
        must_redirect_to work_path(existing_work.id)
      end

      it "renders bad_request for bogus data" do
        updates = { work: { title: nil } }

        expect {
          put work_path(existing_work), params: updates
        }.wont_change "Work.count"

        work = Work.find_by(id: existing_work.id)

        must_respond_with :not_found
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_id = existing_work.id
        existing_work.destroy

        put work_path(bogus_id), params: { work: { title: "Test Title" } }

        must_respond_with :not_found
      end
    end

    describe "guest user" do
      it "will flash error message and redirect if user is not logged in" do
        updates = { work: { title: nil } }
        put work_path(existing_work), params: updates

        expect(flash[:status]).must_equal :failure
        expect(flash[:result_text]).must_equal "You must be logged in to see this page!"
        must_redirect_to root_path
      end
    end
  end

  describe "destroy" do
    describe "logged in user" do
      it "succeeds for an extant work ID" do
        perform_login(user_two)
        expect {
          delete work_path(existing_work.id)
        }.must_change "Work.count", -1

        must_respond_with :redirect
        must_redirect_to root_path
      end

      it "renders 404 not_found and does not update the DB for a bogus work ID" do
        perform_login(user_two)
        bogus_id = existing_work.id
        existing_work.destroy

        expect {
          delete work_path(bogus_id)
        }.wont_change "Work.count"

        must_respond_with :not_found
      end
    end
  end

  describe "upvote" do
    it "redirects to the work page if no user is logged in" do
      post upvote_path(existing_work.id)

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must log in to do that"
      must_respond_with :redirect
    end

    it "redirects to the work page after the user has logged out" do
      perform_login(user_one)
      expect(flash[:result_text]).must_equal "Logged in as returning user #{user_one.name}"
      expect(session[:user_id]).wont_be_nil

      delete logout_path
      expect(session[:user_id]).must_be_nil
      expect(flash[:result_text]).must_equal "Successfully logged out!"
      must_redirect_to root_path
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      another_work = works(:another_album)
      new_user = User.new(username: "me", uid: 876, provider: "github", email: "test@test.com")
      perform_login(new_user)

      expect {
        post upvote_path(another_work.id)
      }.must_change "Vote.count", 1

      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully upvoted!"
      must_respond_with :redirect
    end

    it "redirects to the work page if the user has already voted for that work" do
      perform_login(user_one)
      expect {
        post upvote_path(existing_work.id)
      }.wont_change "Vote.count"

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "Could not upvote"
      must_respond_with :redirect
    end
  end
end
