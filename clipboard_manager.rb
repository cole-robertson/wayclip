#!/usr/bin/env ruby
# Wayclip - Auto-switches between image/path based on focused window

require "fileutils"
require "json"

# Configuration
SAVE_DIR = File.expand_path(ENV["CLIPBOARD_SAVE_DIR"] || "~/Desktop/clipboard-images")
RETENTION_DAYS = (ENV["CLIPBOARD_RETENTION_DAYS"] || "7").to_i
TERMINAL_PATTERN = /ghostty|terminal|konsole|alacritty|kitty|wezterm|foot|tilix|xterm|claude|code|vim|emacs|zed/i

FileUtils.mkdir_p(SAVE_DIR)

# State
@last_image = nil
@last_mode = nil
@last_window = ""
@focus_detection_enabled = false
@last_cleanup = Time.now

def log(msg)
  puts "[CLM] #{msg}"
  $stdout.flush
end

def initialize_focus_detection
  @focus_detection_enabled = system("which hyprctl > /dev/null 2>&1")
  unless @focus_detection_enabled
    log("Warning: Hyprland not detected - auto-switching disabled")
  end
end

def get_focused_window
  return "" unless @focus_detection_enabled
  
  data = JSON.parse(`hyprctl activewindow -j 2>/dev/null`)
  "#{data["class"]} #{data["title"]}".downcase
rescue JSON::ParserError, StandardError
  ""
end


def terminal?(window)
  TERMINAL_PATTERN.match?(window)
end

def save_image(data, mime)
  ext = determine_extension(mime)
  path = build_image_path(ext)
  File.binwrite(path, data)
  path
end

def determine_extension(mime)
  case mime
  when /png/ then ".png"
  when /jpeg|jpg/ then ".jpg"
  else ".png"
  end
end

def build_image_path(ext)
  timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
  File.join(SAVE_DIR, "clipboard-#{timestamp}#{ext}")
end

def set_clipboard_to(type)
  return unless @last_image
  
  case type
  when :path
    copy_path_to_clipboard
  when :image
    copy_image_to_clipboard
  end
end

def copy_path_to_clipboard
  system("echo -n '#{@last_image[:path]}' | wl-copy -t text/plain")
  @last_mode = :path
  log("→ Path mode: #{@last_image[:path]}")
end

def copy_image_to_clipboard
  system("wl-copy -t '#{@last_image[:mime]}' < '#{@last_image[:path]}'")
  @last_mode = :image
  log("→ Image mode")
end

def process_clipboard
  mime_types = get_clipboard_mime_types
  image_mime = find_image_mime(mime_types)
  
  if image_mime
    handle_image_clipboard(image_mime)
  elsif @last_image
    handle_text_clipboard
  end
end

def get_clipboard_mime_types
  `wl-paste -l 2>/dev/null`.strip.split("\n")
end

def find_image_mime(mime_types)
  mime_types.find { |m| m.start_with?("image/") }
end

def handle_image_clipboard(image_mime)
  data = `wl-paste -t "#{image_mime}" 2>/dev/null`
  return if data.empty?
  return if @last_image && data.hash == @last_image[:hash]
  
  path = save_image(data, image_mime)
  @last_image = { path: path, mime: image_mime, hash: data.hash }
  log("Saved: #{path}")
  
  # Only auto-switch if focus detection is available
  if @focus_detection_enabled
    initial_type = terminal?(get_focused_window) ? :path : :image
    set_clipboard_to(initial_type)
  else
    # Default to image mode without focus detection
    set_clipboard_to(:image)
  end
end

def handle_text_clipboard
  text_content = get_clipboard_text
  return if text_content == @last_image[:path]
  
  # User copied different text, clear our image tracking
  log("Different text copied - clearing image tracking")
  clear_image_tracking
end

def get_clipboard_text
  `wl-paste -t text/plain 2>/dev/null`.strip
end

def clear_image_tracking
  @last_image = nil
  @last_mode = nil
end

def handle_focus_change
  return unless @focus_detection_enabled
  
  window = get_focused_window
  return if window == @last_window
  
  @last_window = window
  sync_clipboard_mode(window)
end

def sync_clipboard_mode(window)
  return unless @last_image
  
  target_mode = terminal?(window) ? :path : :image
  set_clipboard_to(target_mode) if @last_mode != target_mode
end

def cleanup_old_images
  return if RETENTION_DAYS <= 0  # Cleanup disabled
  
  now = Time.now
  cutoff_time = now - (RETENTION_DAYS * 24 * 60 * 60)
  removed_count = 0
  
  Dir.glob(File.join(SAVE_DIR, "clipboard-*.{png,jpg,jpeg}")).each do |file|
    begin
      # Use access time (atime) to determine when file was last used
      atime = File.atime(file)
      if atime < cutoff_time
        File.delete(file)
        removed_count += 1
      end
    rescue StandardError => e
      log("Error cleaning #{file}: #{e.message}")
    end
  end
  
  log("Cleaned #{removed_count} old images (>#{RETENTION_DAYS} days)") if removed_count > 0
end

def should_run_cleanup?
  # Run cleanup every hour
  Time.now - @last_cleanup > 3600
end

def run
  initialize_focus_detection
  log("Started - saving to #{SAVE_DIR}")
  log("Terminal apps get paths, others get images") if @focus_detection_enabled
  log("Auto-cleanup: #{RETENTION_DAYS} days retention") if RETENTION_DAYS > 0
  
  # Initial cleanup on startup
  cleanup_old_images
  
  loop do
    process_clipboard
    handle_focus_change
    
    # Periodic cleanup
    if should_run_cleanup?
      cleanup_old_images
      @last_cleanup = Time.now
    end
    
    sleep 0.3
  rescue StandardError => e
    log("Error: #{e.message}")
    sleep 1
  end
rescue Interrupt
  log("Stopped")
end

# Main execution
run