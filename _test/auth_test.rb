require_relative "../_plugins/auth"
require_relative "page"

require "jekyll"
require "jekyll/site"
require "minitest/autorun"

module Hub
  class AuthTest < ::Minitest::Test
    def setup
      @site = ::Jekyll::Site.new ::Jekyll::Configuration::DEFAULTS

      @team = {
        'mbland' => {
          'email' => 'michael.bland@gsa.gov',
          'full_name' => 'Mike Bland'},
        'foobar' => {
          'email' => 'foo.bar@notgsa.gov',
          'full_name' => 'Foo Bar'},
        }

      @guests = [
        {'email' => 'mbland@acm.org',
         'full_name' => 'Mike Bland'},
        {'email' => 'baz.quux@notgsa.gov',
         'full_name' => 'Baz Quux'},
      ]
    end

    def auth_include_pages
      unless @site.pages.empty?
        @site.pages[0..-2]
      else
        []
      end
    end

    def auth_include_users
      auth_include_pages.map {|i| i['user']}
    end

    def auth_include_files
      auth_include_pages.map {|i| File.join(i.dir, i.name)}
    end

    def auth_emails
      unless @site.pages.empty?
        @site.pages.last['addrs']
      else
        []
      end
    end

    def user_include_files(user_ids)
      user_ids.map {|i| File.join('', 'auth', i, 'index.html')}
    end

    def test_empty_team_and_guests
      @site.data['team'] = {}
      @site.data['guest_users'] = []
      Auth.generate_artifacts @site

      assert_empty auth_include_pages
      assert_empty auth_emails
    end

    def test_no_artifacts_in_public_mode
      @site.data['team'] = @team
      @site.data['guest_users'] = @guests
      @site.config['public'] = true
      Auth.generate_artifacts @site

      assert_empty auth_include_pages
      assert_empty auth_emails
    end

    def test_team_artifacts_generated
      @site.data['team'] = @team
      Auth.generate_artifacts @site
      assert_equal([@team['mbland'], @team['foobar']], auth_include_users)

      expected_emails = ['michael.bland@gsa.gov', 'foo.bar@notgsa.gov']
      assert_equal(user_include_files(expected_emails), auth_include_files)
      assert_equal(expected_emails.sort!, auth_emails)
    end

    def test_guest_artifacts_generated
      @site.data['team'] = {}
      @site.data['guest_users'] = @guests
      Auth.generate_artifacts @site
      assert_equal([@guests[0], @guests[1]], auth_include_users)

      expected_emails = ['mbland@acm.org', 'baz.quux@notgsa.gov']
      assert_equal(user_include_files(expected_emails), auth_include_files)
      assert_equal(expected_emails.sort!, auth_emails)
    end

    def test_team_and_guest_artifacts_generated
      @site.data['team'] = @team
      @site.data['guest_users'] = @guests
      Auth.generate_artifacts @site
      assert_equal([@team['mbland'], @team['foobar'], @guests[0], @guests[1]],
        auth_include_users)

      expected_emails = [
        'michael.bland@gsa.gov','foo.bar@notgsa.gov',
        'mbland@acm.org', 'baz.quux@notgsa.gov']
      assert_equal(user_include_files(expected_emails), auth_include_files)
      assert_equal(expected_emails.sort!, auth_emails)
    end
  end
end
