class AddSaveToRepositoryToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :save_to_repository_id, :integer, references: nil

    BuildList.includes(project: :repositories, save_to_platform: :repositories).find_in_batches do |batch|
      batch.each do |bl|
        begin
          project = bl.project
          platform = bl.save_to_platform

          rep = (project.repositories.map(&:id) & platform.repositories.map(&:id)).first

          bl.save_to_repository_id = rep
          bl.save!
        rescue Exception => e
          puts e.inspect
          false
        end
      end
    end
  end

  def self.down
    remove_column :build_lists, :save_to_repository_id
  end
end
