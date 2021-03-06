require 'liquid'

module Hubtrics
  module Reports
    class BranchesWithoutPullsReport < Hubtrics::Reports::Base
      def generate
        branches = client.branches(repository, protected: false)

        branches_without_pulls = []

        branches.each do |branch|
          branch = Hubtrics::Branch.fetch(repository, branch.name)
          print '.'
          next if branch.protected?

          pulls = client.pulls(repository, head: "#{organization}:#{branch.name}", state: 'open')
          branches_without_pulls << branch.to_h if pulls.count < 1
        end

        puts ''

        @report = template.render(
          'data' => branches_without_pulls,
          'repository' => repository,
          'total_branches' => branches.count,
          'total_branches_without_pulls' => branches_without_pulls.count
        ).strip
      end

      private

      # Gets the template for the metrics report.
      #
      # @return [Liquid::Template] The {Liquid::Template} which can be used to render the report.
      def template
        @template ||= Liquid::Template.parse(
          File.read(File.expand_path('../templates/branches_without_pulls.md.liquid', __dir__))
        )
      end

      # Gets the report title.
      #
      # @return [String] The report title.
      def title
        "Hubtrics: Branches without Pulls #{Date.today}"
      end

      # Gets the files for the Gist.
      #
      # @return [Hash] The file hash for the Gist.
      def files
        { 'branches_without_pulls.md' => { content: report } }
      end

      def organization
        organization, = repository.split('/')
        organization
      end
    end
  end
end
