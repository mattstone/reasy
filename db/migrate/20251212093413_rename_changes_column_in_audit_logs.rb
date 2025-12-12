class RenameChangesColumnInAuditLogs < ActiveRecord::Migration[8.1]
  def change
    rename_column :audit_logs, :changes, :recorded_changes
  end
end
