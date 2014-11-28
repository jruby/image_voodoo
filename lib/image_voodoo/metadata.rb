require 'xmpcore-5.1.2.jar'
require 'metadata-extractor-2.7.0.jar'

class ImageVoodoo
  class Metadata
    def initialize(io)
      @metadata = com.drew.imaging.ImageMetadataReader.read_metadata io
    end

    ##
    # This will return a fairly useless Directory if you ask for one
    # and there is no data in the image you are requesting.  The reason
    # for doing this is so queries like 'md[:ISFD0][:Orientation]' can
    # run and just return nil since I think this is the common case.
    #
    # See Directory#exists? if you want to make sure the group you are
    # requesting actually exists or not.
    # 
    def [](dirname)
      dirclass = DIRECTORY_MAP[dirname.to_s]
      raise ArgumentError.new "Uknown metadata group: #{dirname}" unless dirclass
      dirclass.new @metadata
    end

    # Common metadata methods exposed as convenience functions so users
    # do not need to dig around in the various directories
    def make
      self[:IFD0][:Make]
    end

    def model
      self[:IFD0][:Model]
    end

    def orientation
      self[:IFD0][:Orientation]
    end

    # FIXME: I wonder if this needs to fall back to try all other directories
    # for Image Height
    def height
      self['Exif Sub IFD']['Exif Image Height']
    end

    def width
      self['Exif Sub IFD']['Exif Image Width']
    end
  end

  class Directory
    def initialize(metadata)
      @directory = metadata.get_directory self.class.directory_class.java_class
    end

    ##
    # Does the directory you requested exist as metadata for this image.
    def exists?
      !!@directory
    end

    ##
    # Return tag value for the tag specified or nil if there is none
    # defined.
    def [](tag_name)
      return nil unless @directory
      (tag_type, tag_method) = self.class::TAGS[tag_name.to_s]
      raise ArgumentError.new "Unkown tag_name: #{tag_name}" unless tag_type
      java_tag_type = self.class.directory_class.const_get tag_type
      return nil unless @directory.contains_tag java_tag_type
      @directory.__send__ tag_method, java_tag_type
    end
  end

  class AdobeJpegDirectory < Directory
    java_import com.drew.metadata.adobe.AdobeJpegDirectory

    def self.directory_class
      com.drew.metadata.adobe.AdobeJpegDirectory
    end

    TAGS = {
      'Dct Encode Version' => ['TAG_DCT_ENCODE_VERSION', :get_string],
      'App14 Flags0' => ['TAG_APP14_FLAGS0', :get_string],
      'App14 Flags1' => ['TAG_APP14_FLAGS1', :get_string],
      'Color Transform' => ['TAG_COLOR_TRANSFORM', :get_string],
    }
  end

  class BmpHeaderDirectory < Directory
    java_import com.drew.metadata.bmp.BmpHeaderDirectory

    def self.directory_class
      com.drew.metadata.bmp.BmpHeaderDirectory
    end

    TAGS = {
      'Header Size' => ['TAG_HEADER_SIZE', :get_string],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Colour Planes' => ['TAG_COLOUR_PLANES', :get_string],
      'Bits Per Pixel' => ['TAG_BITS_PER_PIXEL', :get_string],
      'Compression' => ['TAG_COMPRESSION', :get_int],
      'X Pixels Per Meter' => ['TAG_X_PIXELS_PER_METER', :get_string],
      'Y Pixels Per Meter' => ['TAG_Y_PIXELS_PER_METER', :get_string],
      'Palette Colour Count' => ['TAG_PALETTE_COLOUR_COUNT', :get_string],
      'Important Colour Count' => ['TAG_IMPORTANT_COLOUR_COUNT', :get_string],
    }
  end

  class ExifIFD0Directory < Directory
    java_import com.drew.metadata.exif.ExifIFD0Directory

    def self.directory_class
      com.drew.metadata.exif.ExifIFD0Directory
    end

    TAGS = {
      'Image Description' => ['TAG_IMAGE_DESCRIPTION', :get_string],
      'Make' => ['TAG_MAKE', :get_string],
      'Model' => ['TAG_MODEL', :get_string],
      'Orientation' => ['TAG_ORIENTATION', :get_int],
      'X Resolution' => ['TAG_X_RESOLUTION', :get_rational],
      'Y Resolution' => ['TAG_Y_RESOLUTION', :get_rational],
      'Resolution Unit' => ['TAG_RESOLUTION_UNIT', :get_int],
      'Software' => ['TAG_SOFTWARE', :get_string],
      'Datetime' => ['TAG_DATETIME', :get_string],
      'Artist' => ['TAG_ARTIST', :get_string],
      'White Point' => ['TAG_WHITE_POINT', :get_rational_array],
      'Primary Chromaticities' => ['TAG_PRIMARY_CHROMATICITIES', :get_rational_array],
      'Ycbcr Coefficients' => ['TAG_YCBCR_COEFFICIENTS', :get_rational_array],
      'Ycbcr Positioning' => ['TAG_YCBCR_POSITIONING', :get_int],
      'Reference Black White' => ['TAG_REFERENCE_BLACK_WHITE', :get_string],
      'Exif Sub Ifd Offset' => ['TAG_EXIF_SUB_IFD_OFFSET', :get_string],
      'Gps Info Offset' => ['TAG_GPS_INFO_OFFSET', :get_string],
      'Copyright' => ['TAG_COPYRIGHT', :get_string],
      'Time Zone Offset' => ['TAG_TIME_ZONE_OFFSET', :get_string],
      'Win Title' => ['TAG_WIN_TITLE', :get_string],
      'Win Comment' => ['TAG_WIN_COMMENT', :get_string],
      'Win Author' => ['TAG_WIN_AUTHOR', :get_string],
      'Win Keywords' => ['TAG_WIN_KEYWORDS', :get_string],
      'Win Subject' => ['TAG_WIN_SUBJECT', :get_string],
    }
  end

  class ExifInteropDirectory < Directory
    java_import com.drew.metadata.exif.ExifInteropDirectory

    def self.directory_class
      com.drew.metadata.exif.ExifInteropDirectory
    end

    TAGS = {
      'Interop Index' => ['TAG_INTEROP_INDEX', :get_string],
      'Interop Version' => ['TAG_INTEROP_VERSION', :get_string],
      'Related Image File Format' => ['TAG_RELATED_IMAGE_FILE_FORMAT', :get_string],
      'Related Image Width' => ['TAG_RELATED_IMAGE_WIDTH', :get_long],
      'Related Image Length' => ['TAG_RELATED_IMAGE_LENGTH', :get_long],
    }
  end

  class ExifSubIFDDirectory < Directory
    java_import com.drew.metadata.exif.ExifSubIFDDirectory

    def self.directory_class
      com.drew.metadata.exif.ExifSubIFDDirectory
    end

    TAGS = {
      'Aperture' => ['TAG_APERTURE', :get_string],
      'Bits Per Sample' => ['TAG_BITS_PER_SAMPLE', :get_int],
      'Photometric Interpretation' => ['TAG_PHOTOMETRIC_INTERPRETATION', :get_int],
      'Thresholding' => ['TAG_THRESHOLDING', :get_int],
      'Fill Order' => ['TAG_FILL_ORDER', :get_int],
      'Document Name' => ['TAG_DOCUMENT_NAME', :get_string],
      'Strip Offsets' => ['TAG_STRIP_OFFSETS', :get_string],
      'Samples Per Pixel' => ['TAG_SAMPLES_PER_PIXEL', :get_int],
      'Rows Per Strip' => ['TAG_ROWS_PER_STRIP', :get_long],
      'Strip Byte Counts' => ['TAG_STRIP_BYTE_COUNTS', :get_long],
      'Min Sample Value' => ['TAG_MIN_SAMPLE_VALUE', :get_int],
      'Max Sample Value' => ['TAG_MAX_SAMPLE_VALUE', :get_int],
      'Planar Configuration' => ['TAG_PLANAR_CONFIGURATION', :get_int],
      'Ycbcr Subsampling' => ['TAG_YCBCR_SUBSAMPLING', :get_string],
      'New Subfile Type' => ['TAG_NEW_SUBFILE_TYPE', :get_string],
      'Subfile Type' => ['TAG_SUBFILE_TYPE', :get_long],
      'Transfer Function' => ['TAG_TRANSFER_FUNCTION', :get_int_array],
      'Predictor' => ['TAG_PREDICTOR', :get_int],
      'Tile Width' => ['TAG_TILE_WIDTH', :get_long],
      'Tile Length' => ['TAG_TILE_LENGTH', :get_long],
      'Tile Offsets' => ['TAG_TILE_OFFSETS', :get_string],
      'Tile Byte Counts' => ['TAG_TILE_BYTE_COUNTS', :get_string],
      'Jpeg Tables' => ['TAG_JPEG_TABLES', :get_string],
      'Cfa Repeat Pattern Dim' => ['TAG_CFA_REPEAT_PATTERN_DIM', :get_string],
      'Cfa Pattern 2' => ['TAG_CFA_PATTERN_2', :get_string],
      'Battery Level' => ['TAG_BATTERY_LEVEL', :get_string],
      'Iptc Naa' => ['TAG_IPTC_NAA', :get_string],
      'Inter Color Profile' => ['TAG_INTER_COLOR_PROFILE', :get_string],
      'Spectral Sensitivity' => ['TAG_SPECTRAL_SENSITIVITY', :get_string],
      'Opto Electric Conversion Function' => ['TAG_OPTO_ELECTRIC_CONVERSION_FUNCTION', :get_string],
      'Interlace' => ['TAG_INTERLACE', :get_string],
      'Time Zone Offset' => ['TAG_TIME_ZONE_OFFSET', :get_string],
      'Self Timer Mode' => ['TAG_SELF_TIMER_MODE', :get_string],
      'Flash Energy' => ['TAG_FLASH_ENERGY', :get_string],
      'Spatial Freq Response' => ['TAG_SPATIAL_FREQ_RESPONSE', :get_string],
      'Noise' => ['TAG_NOISE', :get_string],
      'Image Number' => ['TAG_IMAGE_NUMBER', :get_string],
      'Security Classification' => ['TAG_SECURITY_CLASSIFICATION', :get_string],
      'Image History' => ['TAG_IMAGE_HISTORY', :get_string],
      'Subject Location' => ['TAG_SUBJECT_LOCATION', :get_string],
      'Exposure Index 2' => ['TAG_EXPOSURE_INDEX_2', :get_string],
      'Tiff Ep Standard Id' => ['TAG_TIFF_EP_STANDARD_ID', :get_string],
      'Flash Energy 2' => ['TAG_FLASH_ENERGY_2', :get_string],
      'Spatial Freq Response 2' => ['TAG_SPATIAL_FREQ_RESPONSE_2', :get_string],
      'Subject Location 2' => ['TAG_SUBJECT_LOCATION_2', :get_string],
      'Page Name' => ['TAG_PAGE_NAME', :get_string],
      'Exposure Time' => ['TAG_EXPOSURE_TIME', :get_rational],
      'Fnumber' => ['TAG_FNUMBER', :get_rational],
      'Exposure Program' => ['TAG_EXPOSURE_PROGRAM', :get_string],
      'Iso Equivalent' => ['TAG_ISO_EQUIVALENT', :get_string],
      'Exif Version' => ['TAG_EXIF_VERSION', :get_string],
      'Datetime Original' => ['TAG_DATETIME_ORIGINAL', :get_string],
      'Datetime Digitized' => ['TAG_DATETIME_DIGITIZED', :get_string],
      'Components Configuration' => ['TAG_COMPONENTS_CONFIGURATION', :get_string],
      'Compressed Average Bits Per Pixel' => ['TAG_COMPRESSED_AVERAGE_BITS_PER_PIXEL', :get_string],
      'Shutter Speed' => ['TAG_SHUTTER_SPEED', :get_string],
      'Brightness Value' => ['TAG_BRIGHTNESS_VALUE', :get_string],
      'Exposure Bias' => ['TAG_EXPOSURE_BIAS', :get_string],
      'Max Aperture' => ['TAG_MAX_APERTURE', :get_string],
      'Subject Distance' => ['TAG_SUBJECT_DISTANCE', :get_string],
      'Metering Mode' => ['TAG_METERING_MODE', :get_string],
      'Light Source' => ['TAG_LIGHT_SOURCE', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Flash' => ['TAG_FLASH', :get_string],
      'Focal Length' => ['TAG_FOCAL_LENGTH', :get_string],
      'Makernote' => ['TAG_MAKERNOTE', :get_string],
      'User Comment' => ['TAG_USER_COMMENT', :get_string],
      'Subsecond Time' => ['TAG_SUBSECOND_TIME', :get_string],
      'Subsecond Time Original' => ['TAG_SUBSECOND_TIME_ORIGINAL', :get_string],
      'Subsecond Time Digitized' => ['TAG_SUBSECOND_TIME_DIGITIZED', :get_string],
      'Flashpix Version' => ['TAG_FLASHPIX_VERSION', :get_string],
      'Color Space' => ['TAG_COLOR_SPACE', :get_string],
      'Exif Image Width' => ['TAG_EXIF_IMAGE_WIDTH', :get_long],
      'Exif Image Height' => ['TAG_EXIF_IMAGE_HEIGHT', :get_long],
      'Related Sound File' => ['TAG_RELATED_SOUND_FILE', :get_string],
      'Interop Offset' => ['TAG_INTEROP_OFFSET', :get_string],
      'Focal Plane X Resolution' => ['TAG_FOCAL_PLANE_X_RESOLUTION', :get_string],
      'Focal Plane Y Resolution' => ['TAG_FOCAL_PLANE_Y_RESOLUTION', :get_string],
      'Focal Plane Resolution Unit' => ['TAG_FOCAL_PLANE_RESOLUTION_UNIT', :get_string],
      'Exposure Index' => ['TAG_EXPOSURE_INDEX', :get_string],
      'Sensing Method' => ['TAG_SENSING_METHOD', :get_string],
      'File Source' => ['TAG_FILE_SOURCE', :get_string],
      'Scene Type' => ['TAG_SCENE_TYPE', :get_string],
      'Cfa Pattern' => ['TAG_CFA_PATTERN', :get_string],
      'Custom Rendered' => ['TAG_CUSTOM_RENDERED', :get_string],
      'Exposure Mode' => ['TAG_EXPOSURE_MODE', :get_string],
      'White Balance Mode' => ['TAG_WHITE_BALANCE_MODE', :get_string],
      'Digital Zoom Ratio' => ['TAG_DIGITAL_ZOOM_RATIO', :get_string],
      '35mm Film Equiv Focal Length' => ['TAG_35MM_FILM_EQUIV_FOCAL_LENGTH', :get_string],
      'Scene Capture Type' => ['TAG_SCENE_CAPTURE_TYPE', :get_string],
      'Gain Control' => ['TAG_GAIN_CONTROL', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Device Setting Description' => ['TAG_DEVICE_SETTING_DESCRIPTION', :get_string],
      'Subject Distance Range' => ['TAG_SUBJECT_DISTANCE_RANGE', :get_string],
      'Image Unique Id' => ['TAG_IMAGE_UNIQUE_ID', :get_string],
      'Camera Owner Name' => ['TAG_CAMERA_OWNER_NAME', :get_string],
      'Body Serial Number' => ['TAG_BODY_SERIAL_NUMBER', :get_string],
      'Lens Specification' => ['TAG_LENS_SPECIFICATION', :get_string],
      'Lens Make' => ['TAG_LENS_MAKE', :get_string],
      'Lens Model' => ['TAG_LENS_MODEL', :get_string],
      'Lens Serial Number' => ['TAG_LENS_SERIAL_NUMBER', :get_string],
      'Gamma' => ['TAG_GAMMA', :get_string],
      'Lens' => ['TAG_LENS', :get_string],
    }
  end

  class ExifThumbnailDirectory < Directory
    java_import com.drew.metadata.exif.ExifThumbnailDirectory

    def self.directory_class
      com.drew.metadata.exif.ExifThumbnailDirectory
    end

    TAGS = {
      'Thumbnail Image Width' => ['TAG_THUMBNAIL_IMAGE_WIDTH', :get_long],
      'Thumbnail Image Height' => ['TAG_THUMBNAIL_IMAGE_HEIGHT', :get_long],
      'Bits Per Sample' => ['TAG_BITS_PER_SAMPLE', :get_string],
      'Thumbnail Compression' => ['TAG_THUMBNAIL_COMPRESSION', :get_string],
      'Photometric Interpretation' => ['TAG_PHOTOMETRIC_INTERPRETATION', :get_string],
      'Strip Offsets' => ['TAG_STRIP_OFFSETS', :get_string],
      'Orientation' => ['TAG_ORIENTATION', :get_string],
      'Samples Per Pixel' => ['TAG_SAMPLES_PER_PIXEL', :get_string],
      'Rows Per Strip' => ['TAG_ROWS_PER_STRIP', :get_string],
      'Strip Byte Counts' => ['TAG_STRIP_BYTE_COUNTS', :get_string],
      'X Resolution' => ['TAG_X_RESOLUTION', :get_long],
      'Y Resolution' => ['TAG_Y_RESOLUTION', :get_long],
      'Planar Configuration' => ['TAG_PLANAR_CONFIGURATION', :get_string],
      'Resolution Unit' => ['TAG_RESOLUTION_UNIT', :get_string],
      'Thumbnail Offset' => ['TAG_THUMBNAIL_OFFSET', :get_long],
      'Thumbnail Length' => ['TAG_THUMBNAIL_LENGTH', :get_long],
      'Ycbcr Coefficients' => ['TAG_YCBCR_COEFFICIENTS', :get_rational_array],
      'Ycbcr Subsampling' => ['TAG_YCBCR_SUBSAMPLING', :get_int_array],
      'Ycbcr Positioning' => ['TAG_YCBCR_POSITIONING', :get_int],
      'Reference Black White' => ['TAG_REFERENCE_BLACK_WHITE', :get_rational_array],
    }
  end

  class GpsDirectory < Directory
    java_import com.drew.metadata.exif.GpsDirectory

    def self.directory_class
      com.drew.metadata.exif.GpsDirectory
    end

    TAGS = {
      'Version Id' => ['TAG_VERSION_ID', :get_int_array],
      'Latitude Ref' => ['TAG_LATITUDE_REF', :get_string],
      'Latitude' => ['TAG_LATITUDE', :get_string],
      'Longitude Ref' => ['TAG_LONGITUDE_REF', :get_string],
      'Longitude' => ['TAG_LONGITUDE', :get_string],
      'Altitude Ref' => ['TAG_ALTITUDE_REF', :get_string],
      'Altitude' => ['TAG_ALTITUDE', :get_string],
      'Time Stamp' => ['TAG_TIME_STAMP', :get_string],
      'Satellites' => ['TAG_SATELLITES', :get_string],
      'Status' => ['TAG_STATUS', :get_string],
      'Measure Mode' => ['TAG_MEASURE_MODE', :get_string],
      'Dop' => ['TAG_DOP', :get_string],
      'Speed Ref' => ['TAG_SPEED_REF', :get_string],
      'Speed' => ['TAG_SPEED', :get_string],
      'Track Ref' => ['TAG_TRACK_REF', :get_string],
      'Track' => ['TAG_TRACK', :get_string],
      'Img Direction Ref' => ['TAG_IMG_DIRECTION_REF', :get_string],
      'Img Direction' => ['TAG_IMG_DIRECTION', :get_string],
      'Map Datum' => ['TAG_MAP_DATUM', :get_string],
      'Dest Latitude Ref' => ['TAG_DEST_LATITUDE_REF', :get_string],
      'Dest Latitude' => ['TAG_DEST_LATITUDE', :get_string],
      'Dest Longitude Ref' => ['TAG_DEST_LONGITUDE_REF', :get_string],
      'Dest Longitude' => ['TAG_DEST_LONGITUDE', :get_string],
      'Dest Bearing Ref' => ['TAG_DEST_BEARING_REF', :get_string],
      'Dest Bearing' => ['TAG_DEST_BEARING', :get_string],
      'Dest Distance Ref' => ['TAG_DEST_DISTANCE_REF', :get_string],
      'Dest Distance' => ['TAG_DEST_DISTANCE', :get_string],
      'Processing Method' => ['TAG_PROCESSING_METHOD', :get_string],
      'Area Information' => ['TAG_AREA_INFORMATION', :get_string],
      'Date Stamp' => ['TAG_DATE_STAMP', :get_string],
      'Differential' => ['TAG_DIFFERENTIAL', :get_string],
    }
  end

  class CanonMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.CanonMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.CanonMakernoteDirectory
    end

    TAGS = {
      'Canon Image Type' => ['TAG_CANON_IMAGE_TYPE', :get_string],
      'Canon Firmware Version' => ['TAG_CANON_FIRMWARE_VERSION', :get_string],
      'Canon Image Number' => ['TAG_CANON_IMAGE_NUMBER', :get_string],
      'Canon Owner Name' => ['TAG_CANON_OWNER_NAME', :get_string],
      'Canon Serial Number' => ['TAG_CANON_SERIAL_NUMBER', :get_string],
      'Camera Info Array' => ['TAG_CAMERA_INFO_ARRAY', :get_string],
      'Canon File Length' => ['TAG_CANON_FILE_LENGTH', :get_string],
      'Canon Custom Functions Array' => ['TAG_CANON_CUSTOM_FUNCTIONS_ARRAY', :get_string],
      'Model Id' => ['TAG_MODEL_ID', :get_string],
      'Movie Info Array' => ['TAG_MOVIE_INFO_ARRAY', :get_string],
      'Thumbnail Image Valid Area' => ['TAG_THUMBNAIL_IMAGE_VALID_AREA', :get_string],
      'Serial Number Format' => ['TAG_SERIAL_NUMBER_FORMAT', :get_string],
      'Super Macro' => ['TAG_SUPER_MACRO', :get_string],
      'Date Stamp Mode' => ['TAG_DATE_STAMP_MODE', :get_string],
      'My Colors' => ['TAG_MY_COLORS', :get_string],
      'Firmware Revision' => ['TAG_FIRMWARE_REVISION', :get_string],
      'Categories' => ['TAG_CATEGORIES', :get_string],
      'Face Detect Array 1' => ['TAG_FACE_DETECT_ARRAY_1', :get_string],
      'Face Detect Array 2' => ['TAG_FACE_DETECT_ARRAY_2', :get_string],
      'Af Info Array 2' => ['TAG_AF_INFO_ARRAY_2', :get_string],
      'Image Unique Id' => ['TAG_IMAGE_UNIQUE_ID', :get_string],
      'Raw Data Offset' => ['TAG_RAW_DATA_OFFSET', :get_string],
      'Original Decision Data Offset' => ['TAG_ORIGINAL_DECISION_DATA_OFFSET', :get_string],
      'Custom Functions 1d Array' => ['TAG_CUSTOM_FUNCTIONS_1D_ARRAY', :get_string],
      'Personal Functions Array' => ['TAG_PERSONAL_FUNCTIONS_ARRAY', :get_string],
      'Personal Function Values Array' => ['TAG_PERSONAL_FUNCTION_VALUES_ARRAY', :get_string],
      'File Info Array' => ['TAG_FILE_INFO_ARRAY', :get_string],
      'Af Points In Focus 1d' => ['TAG_AF_POINTS_IN_FOCUS_1D', :get_string],
      'Lens Model' => ['TAG_LENS_MODEL', :get_string],
      'Serial Info Array' => ['TAG_SERIAL_INFO_ARRAY', :get_string],
      'Dust Removal Data' => ['TAG_DUST_REMOVAL_DATA', :get_string],
      'Crop Info' => ['TAG_CROP_INFO', :get_string],
      'Custom Functions Array 2' => ['TAG_CUSTOM_FUNCTIONS_ARRAY_2', :get_string],
      'Aspect Info Array' => ['TAG_ASPECT_INFO_ARRAY', :get_string],
      'Processing Info Array' => ['TAG_PROCESSING_INFO_ARRAY', :get_string],
      'Tone Curve Table' => ['TAG_TONE_CURVE_TABLE', :get_string],
      'Sharpness Table' => ['TAG_SHARPNESS_TABLE', :get_string],
      'Sharpness Freq Table' => ['TAG_SHARPNESS_FREQ_TABLE', :get_string],
      'White Balance Table' => ['TAG_WHITE_BALANCE_TABLE', :get_string],
      'Color Balance Array' => ['TAG_COLOR_BALANCE_ARRAY', :get_string],
      'Measured Color Array' => ['TAG_MEASURED_COLOR_ARRAY', :get_string],
      'Color Temperature' => ['TAG_COLOR_TEMPERATURE', :get_string],
      'Canon Flags Array' => ['TAG_CANON_FLAGS_ARRAY', :get_string],
      'Modified Info Array' => ['TAG_MODIFIED_INFO_ARRAY', :get_string],
      'Tone Curve Matching' => ['TAG_TONE_CURVE_MATCHING', :get_string],
      'White Balance Matching' => ['TAG_WHITE_BALANCE_MATCHING', :get_string],
      'Color Space' => ['TAG_COLOR_SPACE', :get_string],
      'Preview Image Info Array' => ['TAG_PREVIEW_IMAGE_INFO_ARRAY', :get_string],
      'Vrd Offset' => ['TAG_VRD_OFFSET', :get_string],
      'Sensor Info Array' => ['TAG_SENSOR_INFO_ARRAY', :get_string],
      'Color Data Array 2' => ['TAG_COLOR_DATA_ARRAY_2', :get_string],
      'Crw Param' => ['TAG_CRW_PARAM', :get_string],
      'Color Info Array 2' => ['TAG_COLOR_INFO_ARRAY_2', :get_string],
      'Black Level' => ['TAG_BLACK_LEVEL', :get_string],
      'Custom Picture Style File Name' => ['TAG_CUSTOM_PICTURE_STYLE_FILE_NAME', :get_string],
      'Color Info Array' => ['TAG_COLOR_INFO_ARRAY', :get_string],
      'Vignetting Correction Array 1' => ['TAG_VIGNETTING_CORRECTION_ARRAY_1', :get_string],
      'Vignetting Correction Array 2' => ['TAG_VIGNETTING_CORRECTION_ARRAY_2', :get_string],
      'Lighting Optimizer Array' => ['TAG_LIGHTING_OPTIMIZER_ARRAY', :get_string],
      'Lens Info Array' => ['TAG_LENS_INFO_ARRAY', :get_string],
      'Ambiance Info Array' => ['TAG_AMBIANCE_INFO_ARRAY', :get_string],
      'Filter Info Array' => ['TAG_FILTER_INFO_ARRAY', :get_string],
      'Macro Mode' => ['TAG_MACRO_MODE', :get_string],
      'Self Timer Delay' => ['TAG_SELF_TIMER_DELAY', :get_string],
      'Quality' => ['TAG_QUALITY', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'Continuous Drive Mode' => ['TAG_CONTINUOUS_DRIVE_MODE', :get_string],
      'Unknown 2' => ['TAG_UNKNOWN_2', :get_string],
      'Focus Mode 1' => ['TAG_FOCUS_MODE_1', :get_string],
      'Unknown 3' => ['TAG_UNKNOWN_3', :get_string],
      'Unknown 4' => ['TAG_UNKNOWN_4', :get_string],
      'Image Size' => ['TAG_IMAGE_SIZE', :get_string],
      'Easy Shooting Mode' => ['TAG_EASY_SHOOTING_MODE', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Iso' => ['TAG_ISO', :get_int_array],
      'Metering Mode' => ['TAG_METERING_MODE', :get_string],
      'Focus Type' => ['TAG_FOCUS_TYPE', :get_string],
      'Af Point Selected' => ['TAG_AF_POINT_SELECTED', :get_string],
      'Exposure Mode' => ['TAG_EXPOSURE_MODE', :get_string],
      'Unknown 7' => ['TAG_UNKNOWN_7', :get_string],
      'Unknown 8' => ['TAG_UNKNOWN_8', :get_string],
      'Long Focal Length' => ['TAG_LONG_FOCAL_LENGTH', :get_string],
      'Short Focal Length' => ['TAG_SHORT_FOCAL_LENGTH', :get_string],
      'Focal Units Per Mm' => ['TAG_FOCAL_UNITS_PER_MM', :get_string],
      'Unknown 9' => ['TAG_UNKNOWN_9', :get_string],
      'Unknown 10' => ['TAG_UNKNOWN_10', :get_string],
      'Flash Activity' => ['TAG_FLASH_ACTIVITY', :get_string],
      'Flash Details' => ['TAG_FLASH_DETAILS', :get_string],
      'Unknown 12' => ['TAG_UNKNOWN_12', :get_string],
      'Unknown 13' => ['TAG_UNKNOWN_13', :get_string],
      'Focus Mode 2' => ['TAG_FOCUS_MODE_2', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Sequence Number' => ['TAG_SEQUENCE_NUMBER', :get_string],
      'Af Point Used' => ['TAG_AF_POINT_USED', :get_string],
      'Flash Bias' => ['TAG_FLASH_BIAS', :get_string],
      'Auto Exposure Bracketing' => ['TAG_AUTO_EXPOSURE_BRACKETING', :get_string],
      'Aeb Bracket Value' => ['TAG_AEB_BRACKET_VALUE', :get_string],
      'Subject Distance' => ['TAG_SUBJECT_DISTANCE', :get_string],
      'Auto Iso' => ['TAG_AUTO_ISO', :get_string],
      'Base Iso' => ['TAG_BASE_ISO', :get_string],
      'Measured Ev' => ['TAG_MEASURED_EV', :get_string],
      'Target Aperture' => ['TAG_TARGET_APERTURE', :get_string],
      'Target Exposure Time' => ['TAG_TARGET_EXPOSURE_TIME', :get_string],
      'Exposure Compensation' => ['TAG_EXPOSURE_COMPENSATION', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Slow Shutter' => ['TAG_SLOW_SHUTTER', :get_string],
      'Sequence Number' => ['TAG_SEQUENCE_NUMBER', :get_string],
      'Optical Zoom Code' => ['TAG_OPTICAL_ZOOM_CODE', :get_string],
      'Camera Temperature' => ['TAG_CAMERA_TEMPERATURE', :get_string],
      'Flash Guide Number' => ['TAG_FLASH_GUIDE_NUMBER', :get_string],
      'Af Points In Focus' => ['TAG_AF_POINTS_IN_FOCUS', :get_string],
      'Flash Exposure Bracketing' => ['TAG_FLASH_EXPOSURE_BRACKETING', :get_string],
      'Auto Exposure Bracketing' => ['TAG_AUTO_EXPOSURE_BRACKETING', :get_string],
      'Aeb Bracket Value' => ['TAG_AEB_BRACKET_VALUE', :get_string],
      'Control Mode' => ['TAG_CONTROL_MODE', :get_string],
      'Focus Distance Upper' => ['TAG_FOCUS_DISTANCE_UPPER', :get_string],
      'Focus Distance Lower' => ['TAG_FOCUS_DISTANCE_LOWER', :get_string],
      'F Number' => ['TAG_F_NUMBER', :get_string],
      'Exposure Time' => ['TAG_EXPOSURE_TIME', :get_string],
      'Measured Ev 2' => ['TAG_MEASURED_EV_2', :get_string],
      'Bulb Duration' => ['TAG_BULB_DURATION', :get_string],
      'Camera Type' => ['TAG_CAMERA_TYPE', :get_string],
      'Auto Rotate' => ['TAG_AUTO_ROTATE', :get_string],
      'Nd Filter' => ['TAG_ND_FILTER', :get_string],
      'Self Timer 2' => ['TAG_SELF_TIMER_2', :get_string],
      'Flash Output' => ['TAG_FLASH_OUTPUT', :get_string],
      'Panorama Frame Number' => ['TAG_PANORAMA_FRAME_NUMBER', :get_string],
      'Panorama Direction' => ['TAG_PANORAMA_DIRECTION', :get_string],
      'Num Af Points' => ['TAG_NUM_AF_POINTS', :get_string],
      'Valid Af Points' => ['TAG_VALID_AF_POINTS', :get_string],
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Af Image Width' => ['TAG_AF_IMAGE_WIDTH', :get_long],
      'Af Image Height' => ['TAG_AF_IMAGE_HEIGHT', :get_long],
      'Af Area Width' => ['TAG_AF_AREA_WIDTH', :get_string],
      'Af Area Height' => ['TAG_AF_AREA_HEIGHT', :get_string],
      'Af Area X Positions' => ['TAG_AF_AREA_X_POSITIONS', :get_string],
      'Af Area Y Positions' => ['TAG_AF_AREA_Y_POSITIONS', :get_string],
      'Af Points In Focus' => ['TAG_AF_POINTS_IN_FOCUS', :get_string],
      'Primary Af Point 1' => ['TAG_PRIMARY_AF_POINT_1', :get_string],
      'Primary Af Point 2' => ['TAG_PRIMARY_AF_POINT_2', :get_string],
      'Canon Custom Function Long Exposure Noise Reduction' => ['TAG_CANON_CUSTOM_FUNCTION_LONG_EXPOSURE_NOISE_REDUCTION', :get_string],
      'Canon Custom Function Shutter Auto Exposure Lock Buttons' => ['TAG_CANON_CUSTOM_FUNCTION_SHUTTER_AUTO_EXPOSURE_LOCK_BUTTONS', :get_string],
      'Canon Custom Function Mirror Lockup' => ['TAG_CANON_CUSTOM_FUNCTION_MIRROR_LOCKUP', :get_string],
      'Canon Custom Function Tv Av And Exposure Level' => ['TAG_CANON_CUSTOM_FUNCTION_TV_AV_AND_EXPOSURE_LEVEL', :get_string],
      'Canon Custom Function Af Assist Light' => ['TAG_CANON_CUSTOM_FUNCTION_AF_ASSIST_LIGHT', :get_string],
      'Canon Custom Function Shutter Speed In Av Mode' => ['TAG_CANON_CUSTOM_FUNCTION_SHUTTER_SPEED_IN_AV_MODE', :get_string],
      'Canon Custom Function Bracketing' => ['TAG_CANON_CUSTOM_FUNCTION_BRACKETING', :get_string],
      'Canon Custom Function Shutter Curtain Sync' => ['TAG_CANON_CUSTOM_FUNCTION_SHUTTER_CURTAIN_SYNC', :get_string],
      'Canon Custom Function Af Stop' => ['TAG_CANON_CUSTOM_FUNCTION_AF_STOP', :get_string],
      'Canon Custom Function Fill Flash Reduction' => ['TAG_CANON_CUSTOM_FUNCTION_FILL_FLASH_REDUCTION', :get_string],
      'Canon Custom Function Menu Button Return' => ['TAG_CANON_CUSTOM_FUNCTION_MENU_BUTTON_RETURN', :get_string],
      'Canon Custom Function Set Button Function' => ['TAG_CANON_CUSTOM_FUNCTION_SET_BUTTON_FUNCTION', :get_string],
      'Canon Custom Function Sensor Cleaning' => ['TAG_CANON_CUSTOM_FUNCTION_SENSOR_CLEANING', :get_string],
    }
  end

  class CasioType1MakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.CasioType1MakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.CasioType1MakernoteDirectory
    end

    TAGS = {
      'Recording Mode' => ['TAG_RECORDING_MODE', :get_string],
      'Quality' => ['TAG_QUALITY', :get_string],
      'Focusing Mode' => ['TAG_FOCUSING_MODE', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'Flash Intensity' => ['TAG_FLASH_INTENSITY', :get_string],
      'Object Distance' => ['TAG_OBJECT_DISTANCE', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Unknown 1' => ['TAG_UNKNOWN_1', :get_string],
      'Unknown 2' => ['TAG_UNKNOWN_2', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Unknown 3' => ['TAG_UNKNOWN_3', :get_string],
      'Unknown 4' => ['TAG_UNKNOWN_4', :get_string],
      'Unknown 5' => ['TAG_UNKNOWN_5', :get_string],
      'Unknown 6' => ['TAG_UNKNOWN_6', :get_string],
      'Unknown 7' => ['TAG_UNKNOWN_7', :get_string],
      'Unknown 8' => ['TAG_UNKNOWN_8', :get_string],
      'Ccd Sensitivity' => ['TAG_CCD_SENSITIVITY', :get_string],
    }
  end

  class CasioType2MakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.CasioType2MakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.CasioType2MakernoteDirectory
    end

    TAGS = {
      'Thumbnail Dimensions' => ['TAG_THUMBNAIL_DIMENSIONS', :get_string],
      'Thumbnail Size' => ['TAG_THUMBNAIL_SIZE', :get_long],
      'Thumbnail Offset' => ['TAG_THUMBNAIL_OFFSET', :get_long],
      'Quality Mode' => ['TAG_QUALITY_MODE', :get_string],
      'Image Size' => ['TAG_IMAGE_SIZE', :get_string],
      'Focus Mode 1' => ['TAG_FOCUS_MODE_1', :get_string],
      'Iso Sensitivity' => ['TAG_ISO_SENSITIVITY', :get_int],
      'White Balance 1' => ['TAG_WHITE_BALANCE_1', :get_string],
      'Focal Length' => ['TAG_FOCAL_LENGTH', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
      'Preview Thumbnail' => ['TAG_PREVIEW_THUMBNAIL', :get_string],
      'White Balance Bias' => ['TAG_WHITE_BALANCE_BIAS', :get_string],
      'White Balance 2' => ['TAG_WHITE_BALANCE_2', :get_string],
      'Object Distance' => ['TAG_OBJECT_DISTANCE', :get_string],
      'Flash Distance' => ['TAG_FLASH_DISTANCE', :get_string],
      'Record Mode' => ['TAG_RECORD_MODE', :get_string],
      'Self Timer' => ['TAG_SELF_TIMER', :get_string],
      'Quality' => ['TAG_QUALITY', :get_string],
      'Focus Mode 2' => ['TAG_FOCUS_MODE_2', :get_string],
      'Time Zone' => ['TAG_TIME_ZONE', :get_string],
      'Bestshot Mode' => ['TAG_BESTSHOT_MODE', :get_string],
      'Ccd Iso Sensitivity' => ['TAG_CCD_ISO_SENSITIVITY', :get_int],
      'Colour Mode' => ['TAG_COLOUR_MODE', :get_string],
      'Enhancement' => ['TAG_ENHANCEMENT', :get_string],
      'Filter' => ['TAG_FILTER', :get_string],
    }
  end

  class FujifilmMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.FujifilmMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.FujifilmMakernoteDirectory
    end

    TAGS = {
      'Makernote Version' => ['TAG_MAKERNOTE_VERSION', :get_string],
      'Serial Number' => ['TAG_SERIAL_NUMBER', :get_string],
      'Quality' => ['TAG_QUALITY', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Color Saturation' => ['TAG_COLOR_SATURATION', :get_string],
      'Tone' => ['TAG_TONE', :get_string],
      'Color Temperature' => ['TAG_COLOR_TEMPERATURE', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'White Balance Fine Tune' => ['TAG_WHITE_BALANCE_FINE_TUNE', :get_string],
      'Noise Reduction' => ['TAG_NOISE_REDUCTION', :get_string],
      'High Iso Noise Reduction' => ['TAG_HIGH_ISO_NOISE_REDUCTION', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'Flash Ev' => ['TAG_FLASH_EV', :get_string],
      'Macro' => ['TAG_MACRO', :get_string],
      'Focus Mode' => ['TAG_FOCUS_MODE', :get_string],
      'Focus Pixel' => ['TAG_FOCUS_PIXEL', :get_string],
      'Slow Sync' => ['TAG_SLOW_SYNC', :get_string],
      'Picture Mode' => ['TAG_PICTURE_MODE', :get_string],
      'Exr Auto' => ['TAG_EXR_AUTO', :get_string],
      'Exr Mode' => ['TAG_EXR_MODE', :get_string],
      'Auto Bracketing' => ['TAG_AUTO_BRACKETING', :get_string],
      'Sequence Number' => ['TAG_SEQUENCE_NUMBER', :get_string],
      'Fine Pix Color' => ['TAG_FINE_PIX_COLOR', :get_string],
      'Blur Warning' => ['TAG_BLUR_WARNING', :get_string],
      'Focus Warning' => ['TAG_FOCUS_WARNING', :get_string],
      'Auto Exposure Warning' => ['TAG_AUTO_EXPOSURE_WARNING', :get_string],
      'Ge Image Size' => ['TAG_GE_IMAGE_SIZE', :get_string],
      'Dynamic Range' => ['TAG_DYNAMIC_RANGE', :get_string],
      'Film Mode' => ['TAG_FILM_MODE', :get_string],
      'Dynamic Range Setting' => ['TAG_DYNAMIC_RANGE_SETTING', :get_string],
      'Development Dynamic Range' => ['TAG_DEVELOPMENT_DYNAMIC_RANGE', :get_string],
      'Min Focal Length' => ['TAG_MIN_FOCAL_LENGTH', :get_string],
      'Max Focal Length' => ['TAG_MAX_FOCAL_LENGTH', :get_string],
      'Max Aperture At Min Focal' => ['TAG_MAX_APERTURE_AT_MIN_FOCAL', :get_string],
      'Max Aperture At Max Focal' => ['TAG_MAX_APERTURE_AT_MAX_FOCAL', :get_string],
      'Auto Dynamic Range' => ['TAG_AUTO_DYNAMIC_RANGE', :get_string],
      'Faces Detected' => ['TAG_FACES_DETECTED', :get_string],
      'Face Positions' => ['TAG_FACE_POSITIONS', :get_string],
      'Face Rec Info' => ['TAG_FACE_REC_INFO', :get_string],
      'File Source' => ['TAG_FILE_SOURCE', :get_string],
      'Order Number' => ['TAG_ORDER_NUMBER', :get_string],
      'Frame Number' => ['TAG_FRAME_NUMBER', :get_string],
      'Parallax' => ['TAG_PARALLAX', :get_string],
    }
  end

  class KyoceraMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.KyoceraMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.KyoceraMakernoteDirectory
    end

    TAGS = {
      'Proprietary Thumbnail' => ['TAG_PROPRIETARY_THUMBNAIL', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
    }
  end

  class LeicaMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.LeicaMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.LeicaMakernoteDirectory
    end

    TAGS = {
      'Quality' => ['TAG_QUALITY', :get_string],
      'User Profile' => ['TAG_USER_PROFILE', :get_string],
      'Serial Number' => ['TAG_SERIAL_NUMBER', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Lens Type' => ['TAG_LENS_TYPE', :get_string],
      'External Sensor Brightness Value' => ['TAG_EXTERNAL_SENSOR_BRIGHTNESS_VALUE', :get_string],
      'Measured Lv' => ['TAG_MEASURED_LV', :get_string],
      'Approximate F Number' => ['TAG_APPROXIMATE_F_NUMBER', :get_string],
      'Camera Temperature' => ['TAG_CAMERA_TEMPERATURE', :get_string],
      'Color Temperature' => ['TAG_COLOR_TEMPERATURE', :get_string],
      'Wb Red Level' => ['TAG_WB_RED_LEVEL', :get_string],
      'Wb Green Level' => ['TAG_WB_GREEN_LEVEL', :get_string],
      'Wb Blue Level' => ['TAG_WB_BLUE_LEVEL', :get_string],
      'Ccd Version' => ['TAG_CCD_VERSION', :get_string],
      'Ccd Board Version' => ['TAG_CCD_BOARD_VERSION', :get_string],
      'Controller Board Version' => ['TAG_CONTROLLER_BOARD_VERSION', :get_string],
      'M16 C Version' => ['TAG_M16_C_VERSION', :get_string],
      'Image Id Number' => ['TAG_IMAGE_ID_NUMBER', :get_string],
    }
  end

  class NikonType1MakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.NikonType1MakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.NikonType1MakernoteDirectory
    end

    TAGS = {
      'Unknown 1' => ['TAG_UNKNOWN_1', :get_string],
      'Quality' => ['TAG_QUALITY', :get_string],
      'Color Mode' => ['TAG_COLOR_MODE', :get_string],
      'Image Adjustment' => ['TAG_IMAGE_ADJUSTMENT', :get_string],
      'Ccd Sensitivity' => ['TAG_CCD_SENSITIVITY', :get_int],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Focus' => ['TAG_FOCUS', :get_string],
      'Unknown 2' => ['TAG_UNKNOWN_2', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Converter' => ['TAG_CONVERTER', :get_string],
      'Unknown 3' => ['TAG_UNKNOWN_3', :get_string],
    }
  end

  class NikonType2MakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.NikonType2MakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.NikonType2MakernoteDirectory
    end

    TAGS = {
      'Firmware Version' => ['TAG_FIRMWARE_VERSION', :get_string],
      'Iso 1' => ['TAG_ISO_1', :get_string],
      'Color Mode' => ['TAG_COLOR_MODE', :get_string],
      'Quality And File Format' => ['TAG_QUALITY_AND_FILE_FORMAT', :get_string],
      'Camera White Balance' => ['TAG_CAMERA_WHITE_BALANCE', :get_string],
      'Camera Sharpening' => ['TAG_CAMERA_SHARPENING', :get_string],
      'Af Type' => ['TAG_AF_TYPE', :get_string],
      'Flash Sync Mode' => ['TAG_FLASH_SYNC_MODE', :get_string],
      'Auto Flash Mode' => ['TAG_AUTO_FLASH_MODE', :get_string],
      'Unknown 34' => ['TAG_UNKNOWN_34', :get_string],
      'Camera White Balance Fine' => ['TAG_CAMERA_WHITE_BALANCE_FINE', :get_string],
      'Camera White Balance Rb Coeff' => ['TAG_CAMERA_WHITE_BALANCE_RB_COEFF', :get_string],
      'Program Shift' => ['TAG_PROGRAM_SHIFT', :get_string],
      'Exposure Difference' => ['TAG_EXPOSURE_DIFFERENCE', :get_string],
      'Iso Mode' => ['TAG_ISO_MODE', :get_string],
      'Data Dump' => ['TAG_DATA_DUMP', :get_string],
      'Preview Ifd' => ['TAG_PREVIEW_IFD', :get_string],
      'Auto Flash Compensation' => ['TAG_AUTO_FLASH_COMPENSATION', :get_string],
      'Iso Requested' => ['TAG_ISO_REQUESTED', :get_string],
      'Image Boundary' => ['TAG_IMAGE_BOUNDARY', :get_string],
      'Flash Exposure Compensation' => ['TAG_FLASH_EXPOSURE_COMPENSATION', :get_string],
      'Flash Bracket Compensation' => ['TAG_FLASH_BRACKET_COMPENSATION', :get_string],
      'Ae Bracket Compensation' => ['TAG_AE_BRACKET_COMPENSATION', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'Crop High Speed' => ['TAG_CROP_HIGH_SPEED', :get_string],
      'Exposure Tuning' => ['TAG_EXPOSURE_TUNING', :get_string],
      'Camera Serial Number' => ['TAG_CAMERA_SERIAL_NUMBER', :get_string],
      'Color Space' => ['TAG_COLOR_SPACE', :get_string],
      'Vr Info' => ['TAG_VR_INFO', :get_string],
      'Image Authentication' => ['TAG_IMAGE_AUTHENTICATION', :get_string],
      'Unknown 35' => ['TAG_UNKNOWN_35', :get_string],
      'Active D Lighting' => ['TAG_ACTIVE_D_LIGHTING', :get_string],
      'Picture Control' => ['TAG_PICTURE_CONTROL', :get_string],
      'World Time' => ['TAG_WORLD_TIME', :get_string],
      'Iso Info' => ['TAG_ISO_INFO', :get_string],
      'Unknown 36' => ['TAG_UNKNOWN_36', :get_string],
      'Unknown 37' => ['TAG_UNKNOWN_37', :get_string],
      'Unknown 38' => ['TAG_UNKNOWN_38', :get_string],
      'Unknown 39' => ['TAG_UNKNOWN_39', :get_string],
      'Vignette Control' => ['TAG_VIGNETTE_CONTROL', :get_string],
      'Unknown 40' => ['TAG_UNKNOWN_40', :get_string],
      'Unknown 41' => ['TAG_UNKNOWN_41', :get_string],
      'Unknown 42' => ['TAG_UNKNOWN_42', :get_string],
      'Unknown 43' => ['TAG_UNKNOWN_43', :get_string],
      'Unknown 44' => ['TAG_UNKNOWN_44', :get_string],
      'Unknown 45' => ['TAG_UNKNOWN_45', :get_string],
      'Unknown 46' => ['TAG_UNKNOWN_46', :get_string],
      'Image Adjustment' => ['TAG_IMAGE_ADJUSTMENT', :get_string],
      'Camera Tone Compensation' => ['TAG_CAMERA_TONE_COMPENSATION', :get_string],
      'Adapter' => ['TAG_ADAPTER', :get_string],
      'Lens Type' => ['TAG_LENS_TYPE', :get_string],
      'Lens' => ['TAG_LENS', :get_string],
      'Manual Focus Distance' => ['TAG_MANUAL_FOCUS_DISTANCE', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Flash Used' => ['TAG_FLASH_USED', :get_string],
      'Af Focus Position' => ['TAG_AF_FOCUS_POSITION', :get_string],
      'Shooting Mode' => ['TAG_SHOOTING_MODE', :get_string],
      'Unknown 20' => ['TAG_UNKNOWN_20', :get_string],
      'Lens Stops' => ['TAG_LENS_STOPS', :get_string],
      'Contrast Curve' => ['TAG_CONTRAST_CURVE', :get_string],
      'Camera Color Mode' => ['TAG_CAMERA_COLOR_MODE', :get_string],
      'Unknown 47' => ['TAG_UNKNOWN_47', :get_string],
      'Scene Mode' => ['TAG_SCENE_MODE', :get_string],
      'Light Source' => ['TAG_LIGHT_SOURCE', :get_string],
      'Shot Info' => ['TAG_SHOT_INFO', :get_string],
      'Camera Hue Adjustment' => ['TAG_CAMERA_HUE_ADJUSTMENT', :get_string],
      'Nef Compression' => ['TAG_NEF_COMPRESSION', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Noise Reduction' => ['TAG_NOISE_REDUCTION', :get_string],
      'Linearization Table' => ['TAG_LINEARIZATION_TABLE', :get_string],
      'Color Balance' => ['TAG_COLOR_BALANCE', :get_string],
      'Lens Data' => ['TAG_LENS_DATA', :get_string],
      'Nef Thumbnail Size' => ['TAG_NEF_THUMBNAIL_SIZE', :get_long],
      'Sensor Pixel Size' => ['TAG_SENSOR_PIXEL_SIZE', :get_string],
      'Unknown 10' => ['TAG_UNKNOWN_10', :get_string],
      'Scene Assist' => ['TAG_SCENE_ASSIST', :get_string],
      'Unknown 11' => ['TAG_UNKNOWN_11', :get_string],
      'Retouch History' => ['TAG_RETOUCH_HISTORY', :get_string],
      'Unknown 12' => ['TAG_UNKNOWN_12', :get_string],
      'Camera Serial Number 2' => ['TAG_CAMERA_SERIAL_NUMBER_2', :get_string],
      'Image Data Size' => ['TAG_IMAGE_DATA_SIZE', :get_string],
      'Unknown 27' => ['TAG_UNKNOWN_27', :get_string],
      'Unknown 28' => ['TAG_UNKNOWN_28', :get_string],
      'Image Count' => ['TAG_IMAGE_COUNT', :get_string],
      'Deleted Image Count' => ['TAG_DELETED_IMAGE_COUNT', :get_string],
      'Exposure Sequence Number' => ['TAG_EXPOSURE_SEQUENCE_NUMBER', :get_string],
      'Flash Info' => ['TAG_FLASH_INFO', :get_string],
      'Image Optimisation' => ['TAG_IMAGE_OPTIMISATION', :get_string],
      'Saturation 2' => ['TAG_SATURATION_2', :get_string],
      'Digital Vari Program' => ['TAG_DIGITAL_VARI_PROGRAM', :get_string],
      'Image Stabilisation' => ['TAG_IMAGE_STABILISATION', :get_string],
      'Af Response' => ['TAG_AF_RESPONSE', :get_string],
      'Unknown 29' => ['TAG_UNKNOWN_29', :get_string],
      'Unknown 30' => ['TAG_UNKNOWN_30', :get_string],
      'Multi Exposure' => ['TAG_MULTI_EXPOSURE', :get_string],
      'High Iso Noise Reduction' => ['TAG_HIGH_ISO_NOISE_REDUCTION', :get_string],
      'Unknown 31' => ['TAG_UNKNOWN_31', :get_string],
      'Unknown 32' => ['TAG_UNKNOWN_32', :get_string],
      'Unknown 33' => ['TAG_UNKNOWN_33', :get_string],
      'Unknown 48' => ['TAG_UNKNOWN_48', :get_string],
      'Power Up Time' => ['TAG_POWER_UP_TIME', :get_string],
      'Af Info 2' => ['TAG_AF_INFO_2', :get_string],
      'File Info' => ['TAG_FILE_INFO', :get_string],
      'Af Tune' => ['TAG_AF_TUNE', :get_string],
      'Unknown 49' => ['TAG_UNKNOWN_49', :get_string],
      'Unknown 50' => ['TAG_UNKNOWN_50', :get_string],
      'Unknown 51' => ['TAG_UNKNOWN_51', :get_string],
      'Print Im' => ['TAG_PRINT_IM', :get_string],
      'Nikon Capture Data' => ['TAG_NIKON_CAPTURE_DATA', :get_string],
      'Unknown 52' => ['TAG_UNKNOWN_52', :get_string],
      'Unknown 53' => ['TAG_UNKNOWN_53', :get_string],
      'Nikon Capture Version' => ['TAG_NIKON_CAPTURE_VERSION', :get_string],
      'Nikon Capture Offsets' => ['TAG_NIKON_CAPTURE_OFFSETS', :get_string],
      'Nikon Scan' => ['TAG_NIKON_SCAN', :get_string],
      'Unknown 54' => ['TAG_UNKNOWN_54', :get_string],
      'Nef Bit Depth' => ['TAG_NEF_BIT_DEPTH', :get_string],
      'Unknown 55' => ['TAG_UNKNOWN_55', :get_string],
    }
  end

  class OlympusMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.OlympusMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.OlympusMakernoteDirectory
    end

    TAGS = {
      'Makernote Version' => ['TAG_MAKERNOTE_VERSION', :get_string],
      'Camera Settings 1' => ['TAG_CAMERA_SETTINGS_1', :get_string],
      'Camera Settings 2' => ['TAG_CAMERA_SETTINGS_2', :get_string],
      'Compressed Image Size' => ['TAG_COMPRESSED_IMAGE_SIZE', :get_long],
      'Minolta Thumbnail Offset 1' => ['TAG_MINOLTA_THUMBNAIL_OFFSET_1', :get_long],
      'Minolta Thumbnail Offset 2' => ['TAG_MINOLTA_THUMBNAIL_OFFSET_2', :get_long],
      'Minolta Thumbnail Length' => ['TAG_MINOLTA_THUMBNAIL_LENGTH', :get_long],
      'Colour Mode' => ['TAG_COLOUR_MODE', :get_string],
      'Image Quality 1' => ['TAG_IMAGE_QUALITY_1', :get_string],
      'Image Quality 2' => ['TAG_IMAGE_QUALITY_2', :get_string],
      'Special Mode' => ['TAG_SPECIAL_MODE', :get_string],
      'Jpeg Quality' => ['TAG_JPEG_QUALITY', :get_string],
      'Macro Mode' => ['TAG_MACRO_MODE', :get_string],
      'Bw Mode' => ['TAG_BW_MODE', :get_string],
      'Digi Zoom Ratio' => ['TAG_DIGI_ZOOM_RATIO', :get_string],
      'Focal Plane Diagonal' => ['TAG_FOCAL_PLANE_DIAGONAL', :get_string],
      'Lens Distortion Parameters' => ['TAG_LENS_DISTORTION_PARAMETERS', :get_string],
      'Firmware Version' => ['TAG_FIRMWARE_VERSION', :get_string],
      'Pict Info' => ['TAG_PICT_INFO', :get_string],
      'Camera Id' => ['TAG_CAMERA_ID', :get_string],
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Original Manufacturer Model' => ['TAG_ORIGINAL_MANUFACTURER_MODEL', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
      'Data Dump' => ['TAG_DATA_DUMP', :get_string],
      'Shutter Speed Value' => ['TAG_SHUTTER_SPEED_VALUE', :get_string],
      'Iso Value' => ['TAG_ISO_VALUE', :get_string],
      'Aperture Value' => ['TAG_APERTURE_VALUE', :get_string],
      'Brightness Value' => ['TAG_BRIGHTNESS_VALUE', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'Bracket' => ['TAG_BRACKET', :get_string],
      'Focus Range' => ['TAG_FOCUS_RANGE', :get_string],
      'Focus Mode' => ['TAG_FOCUS_MODE', :get_string],
      'Focus Distance' => ['TAG_FOCUS_DISTANCE', :get_string],
      'Zoom' => ['TAG_ZOOM', :get_string],
      'Macro Focus' => ['TAG_MACRO_FOCUS', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Colour Matrix' => ['TAG_COLOUR_MATRIX', :get_string],
      'Black Level' => ['TAG_BLACK_LEVEL', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Red Bias' => ['TAG_RED_BIAS', :get_string],
      'Blue Bias' => ['TAG_BLUE_BIAS', :get_string],
      'Serial Number' => ['TAG_SERIAL_NUMBER', :get_string],
      'Flash Bias' => ['TAG_FLASH_BIAS', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Sharpness Factor' => ['TAG_SHARPNESS_FACTOR', :get_string],
      'Colour Control' => ['TAG_COLOUR_CONTROL', :get_string],
      'Valid Bits' => ['TAG_VALID_BITS', :get_string],
      'Coring Filter' => ['TAG_CORING_FILTER', :get_string],
      'Final Width' => ['TAG_FINAL_WIDTH', :get_string],
      'Final Height' => ['TAG_FINAL_HEIGHT', :get_string],
      'Compression Ratio' => ['TAG_COMPRESSION_RATIO', :get_string],
      'Exposure Mode' => ['TAG_EXPOSURE_MODE', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Image Size' => ['TAG_IMAGE_SIZE', :get_string],
      'Image Quality' => ['TAG_IMAGE_QUALITY', :get_string],
      'Shooting Mode' => ['TAG_SHOOTING_MODE', :get_string],
      'Metering Mode' => ['TAG_METERING_MODE', :get_string],
      'Apex Film Speed Value' => ['TAG_APEX_FILM_SPEED_VALUE', :get_string],
      'Apex Shutter Speed Time Value' => ['TAG_APEX_SHUTTER_SPEED_TIME_VALUE', :get_string],
      'Apex Aperture Value' => ['TAG_APEX_APERTURE_VALUE', :get_string],
      'Macro Mode' => ['TAG_MACRO_MODE', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Exposure Compensation' => ['TAG_EXPOSURE_COMPENSATION', :get_string],
      'Bracket Step' => ['TAG_BRACKET_STEP', :get_string],
      'Interval Length' => ['TAG_INTERVAL_LENGTH', :get_string],
      'Interval Number' => ['TAG_INTERVAL_NUMBER', :get_string],
      'Focal Length' => ['TAG_FOCAL_LENGTH', :get_string],
      'Focus Distance' => ['TAG_FOCUS_DISTANCE', :get_string],
      'Flash Fired' => ['TAG_FLASH_FIRED', :get_string],
      'Date' => ['TAG_DATE', :get_string],
      'Time' => ['TAG_TIME', :get_string],
      'Max Aperture At Focal Length' => ['TAG_MAX_APERTURE_AT_FOCAL_LENGTH', :get_string],
      'File Number Memory' => ['TAG_FILE_NUMBER_MEMORY', :get_string],
      'Last File Number' => ['TAG_LAST_FILE_NUMBER', :get_string],
      'White Balance Red' => ['TAG_WHITE_BALANCE_RED', :get_string],
      'White Balance Green' => ['TAG_WHITE_BALANCE_GREEN', :get_string],
      'White Balance Blue' => ['TAG_WHITE_BALANCE_BLUE', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Subject Program' => ['TAG_SUBJECT_PROGRAM', :get_string],
      'Flash Compensation' => ['TAG_FLASH_COMPENSATION', :get_string],
      'Iso Setting' => ['TAG_ISO_SETTING', :get_string],
      'Camera Model' => ['TAG_CAMERA_MODEL', :get_string],
      'Interval Mode' => ['TAG_INTERVAL_MODE', :get_string],
      'Folder Name' => ['TAG_FOLDER_NAME', :get_string],
      'Color Mode' => ['TAG_COLOR_MODE', :get_string],
      'Color Filter' => ['TAG_COLOR_FILTER', :get_string],
      'Black And White Filter' => ['TAG_BLACK_AND_WHITE_FILTER', :get_string],
      'Internal Flash' => ['TAG_INTERNAL_FLASH', :get_string],
      'Apex Brightness Value' => ['TAG_APEX_BRIGHTNESS_VALUE', :get_string],
      'Spot Focus Point X Coordinate' => ['TAG_SPOT_FOCUS_POINT_X_COORDINATE', :get_string],
      'Spot Focus Point Y Coordinate' => ['TAG_SPOT_FOCUS_POINT_Y_COORDINATE', :get_string],
      'Wide Focus Zone' => ['TAG_WIDE_FOCUS_ZONE', :get_string],
      'Focus Mode' => ['TAG_FOCUS_MODE', :get_string],
      'Focus Area' => ['TAG_FOCUS_AREA', :get_string],
      'Dec Switch Position' => ['TAG_DEC_SWITCH_POSITION', :get_string],
    }
  end

  class PanasonicMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.PanasonicMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.PanasonicMakernoteDirectory
    end

    TAGS = {
      'Quality Mode' => ['TAG_QUALITY_MODE', :get_string],
      'Firmware Version' => ['TAG_FIRMWARE_VERSION', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Focus Mode' => ['TAG_FOCUS_MODE', :get_string],
      'Af Area Mode' => ['TAG_AF_AREA_MODE', :get_string],
      'Image Stabilization' => ['TAG_IMAGE_STABILIZATION', :get_string],
      'Macro Mode' => ['TAG_MACRO_MODE', :get_string],
      'Record Mode' => ['TAG_RECORD_MODE', :get_string],
      'Audio' => ['TAG_AUDIO', :get_string],
      'Unknown Data Dump' => ['TAG_UNKNOWN_DATA_DUMP', :get_string],
      'Easy Mode' => ['TAG_EASY_MODE', :get_string],
      'White Balance Bias' => ['TAG_WHITE_BALANCE_BIAS', :get_string],
      'Flash Bias' => ['TAG_FLASH_BIAS', :get_string],
      'Internal Serial Number' => ['TAG_INTERNAL_SERIAL_NUMBER', :get_string],
      'Exif Version' => ['TAG_EXIF_VERSION', :get_string],
      'Color Effect' => ['TAG_COLOR_EFFECT', :get_string],
      'Uptime' => ['TAG_UPTIME', :get_string],
      'Burst Mode' => ['TAG_BURST_MODE', :get_string],
      'Sequence Number' => ['TAG_SEQUENCE_NUMBER', :get_string],
      'Contrast Mode' => ['TAG_CONTRAST_MODE', :get_string],
      'Noise Reduction' => ['TAG_NOISE_REDUCTION', :get_string],
      'Self Timer' => ['TAG_SELF_TIMER', :get_string],
      'Rotation' => ['TAG_ROTATION', :get_string],
      'Af Assist Lamp' => ['TAG_AF_ASSIST_LAMP', :get_string],
      'Color Mode' => ['TAG_COLOR_MODE', :get_string],
      'Baby Age' => ['TAG_BABY_AGE', :get_string],
      'Optical Zoom Mode' => ['TAG_OPTICAL_ZOOM_MODE', :get_string],
      'Conversion Lens' => ['TAG_CONVERSION_LENS', :get_string],
      'Travel Day' => ['TAG_TRAVEL_DAY', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'World Time Location' => ['TAG_WORLD_TIME_LOCATION', :get_string],
      'Text Stamp' => ['TAG_TEXT_STAMP', :get_string],
      'Program Iso' => ['TAG_PROGRAM_ISO', :get_string],
      'Advanced Scene Mode' => ['TAG_ADVANCED_SCENE_MODE', :get_string],
      'Text Stamp 1' => ['TAG_TEXT_STAMP_1', :get_string],
      'Faces Detected' => ['TAG_FACES_DETECTED', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Film Mode' => ['TAG_FILM_MODE', :get_string],
      'Wb Adjust Ab' => ['TAG_WB_ADJUST_AB', :get_string],
      'Wb Adjust Gm' => ['TAG_WB_ADJUST_GM', :get_string],
      'Af Point Position' => ['TAG_AF_POINT_POSITION', :get_string],
      'Face Detection Info' => ['TAG_FACE_DETECTION_INFO', :get_string],
      'Lens Type' => ['TAG_LENS_TYPE', :get_string],
      'Lens Serial Number' => ['TAG_LENS_SERIAL_NUMBER', :get_string],
      'Accessory Type' => ['TAG_ACCESSORY_TYPE', :get_string],
      'Transform' => ['TAG_TRANSFORM', :get_string],
      'Intelligent Exposure' => ['TAG_INTELLIGENT_EXPOSURE', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
      'Face Recognition Info' => ['TAG_FACE_RECOGNITION_INFO', :get_string],
      'Flash Warning' => ['TAG_FLASH_WARNING', :get_string],
      'Recognized Face Flags' => ['TAG_RECOGNIZED_FACE_FLAGS', :get_string],
      'Title' => ['TAG_TITLE', :get_string],
      'Baby Name' => ['TAG_BABY_NAME', :get_string],
      'Location' => ['TAG_LOCATION', :get_string],
      'Country' => ['TAG_COUNTRY', :get_string],
      'State' => ['TAG_STATE', :get_string],
      'City' => ['TAG_CITY', :get_string],
      'Landmark' => ['TAG_LANDMARK', :get_string],
      'Intelligent Resolution' => ['TAG_INTELLIGENT_RESOLUTION', :get_string],
      'Makernote Version' => ['TAG_MAKERNOTE_VERSION', :get_string],
      'Scene Mode' => ['TAG_SCENE_MODE', :get_string],
      'Wb Red Level' => ['TAG_WB_RED_LEVEL', :get_string],
      'Wb Green Level' => ['TAG_WB_GREEN_LEVEL', :get_string],
      'Wb Blue Level' => ['TAG_WB_BLUE_LEVEL', :get_string],
      'Flash Fired' => ['TAG_FLASH_FIRED', :get_string],
      'Text Stamp 2' => ['TAG_TEXT_STAMP_2', :get_string],
      'Text Stamp 3' => ['TAG_TEXT_STAMP_3', :get_string],
      'Baby Age 1' => ['TAG_BABY_AGE_1', :get_string],
      'Transform 1' => ['TAG_TRANSFORM_1', :get_string],
    }
  end

  class PentaxMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.PentaxMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.PentaxMakernoteDirectory
    end

    TAGS = {
      'Capture Mode' => ['TAG_CAPTURE_MODE', :get_string],
      'Quality Level' => ['TAG_QUALITY_LEVEL', :get_string],
      'Focus Mode' => ['TAG_FOCUS_MODE', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Iso Speed' => ['TAG_ISO_SPEED', :get_string],
      'Colour' => ['TAG_COLOUR', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
      'Time Zone' => ['TAG_TIME_ZONE', :get_string],
      'Daylight Savings' => ['TAG_DAYLIGHT_SAVINGS', :get_string],
    }
  end

  class RicohMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.RicohMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.RicohMakernoteDirectory
    end

    TAGS = {
      'Makernote Data Type' => ['TAG_MAKERNOTE_DATA_TYPE', :get_string],
      'Version' => ['TAG_VERSION', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
      'Ricoh Camera Info Makernote Sub Ifd Pointer' => ['TAG_RICOH_CAMERA_INFO_MAKERNOTE_SUB_IFD_POINTER', :get_string],
    }
  end

  class SanyoMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.SanyoMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.SanyoMakernoteDirectory
    end

    TAGS = {
      'Makernote Offset' => ['TAG_MAKERNOTE_OFFSET', :get_string],
      'Sanyo Thumbnail' => ['TAG_SANYO_THUMBNAIL', :get_string],
      'Special Mode' => ['TAG_SPECIAL_MODE', :get_string],
      'Sanyo Quality' => ['TAG_SANYO_QUALITY', :get_string],
      'Macro' => ['TAG_MACRO', :get_string],
      'Digital Zoom' => ['TAG_DIGITAL_ZOOM', :get_string],
      'Software Version' => ['TAG_SOFTWARE_VERSION', :get_string],
      'Pict Info' => ['TAG_PICT_INFO', :get_string],
      'Camera Id' => ['TAG_CAMERA_ID', :get_string],
      'Sequential Shot' => ['TAG_SEQUENTIAL_SHOT', :get_string],
      'Wide Range' => ['TAG_WIDE_RANGE', :get_string],
      'Color Adjustment Mode' => ['TAG_COLOR_ADJUSTMENT_MODE', :get_string],
      'Quick Shot' => ['TAG_QUICK_SHOT', :get_string],
      'Self Timer' => ['TAG_SELF_TIMER', :get_string],
      'Voice Memo' => ['TAG_VOICE_MEMO', :get_string],
      'Record Shutter Release' => ['TAG_RECORD_SHUTTER_RELEASE', :get_string],
      'Flicker Reduce' => ['TAG_FLICKER_REDUCE', :get_string],
      'Optical Zoom On' => ['TAG_OPTICAL_ZOOM_ON', :get_string],
      'Digital Zoom On' => ['TAG_DIGITAL_ZOOM_ON', :get_string],
      'Light Source Special' => ['TAG_LIGHT_SOURCE_SPECIAL', :get_string],
      'Resaved' => ['TAG_RESAVED', :get_string],
      'Scene Select' => ['TAG_SCENE_SELECT', :get_string],
      'Manual Focus Distance Or Face Info' => ['TAG_MANUAL_FOCUS_DISTANCE_OR_FACE_INFO', :get_string],
      'Sequence Shot Interval' => ['TAG_SEQUENCE_SHOT_INTERVAL', :get_string],
      'Flash Mode' => ['TAG_FLASH_MODE', :get_string],
      'Print Im' => ['TAG_PRINT_IM', :get_string],
      'Data Dump' => ['TAG_DATA_DUMP', :get_string],
    }
  end

  class SigmaMakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.SigmaMakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.SigmaMakernoteDirectory
    end

    TAGS = {
      'Serial Number' => ['TAG_SERIAL_NUMBER', :get_string],
      'Drive Mode' => ['TAG_DRIVE_MODE', :get_string],
      'Resolution Mode' => ['TAG_RESOLUTION_MODE', :get_string],
      'Auto Focus Mode' => ['TAG_AUTO_FOCUS_MODE', :get_string],
      'Focus Setting' => ['TAG_FOCUS_SETTING', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Exposure Mode' => ['TAG_EXPOSURE_MODE', :get_string],
      'Metering Mode' => ['TAG_METERING_MODE', :get_string],
      'Lens Range' => ['TAG_LENS_RANGE', :get_string],
      'Color Space' => ['TAG_COLOR_SPACE', :get_string],
      'Exposure' => ['TAG_EXPOSURE', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Shadow' => ['TAG_SHADOW', :get_string],
      'Highlight' => ['TAG_HIGHLIGHT', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Fill Light' => ['TAG_FILL_LIGHT', :get_string],
      'Color Adjustment' => ['TAG_COLOR_ADJUSTMENT', :get_string],
      'Adjustment Mode' => ['TAG_ADJUSTMENT_MODE', :get_string],
      'Quality' => ['TAG_QUALITY', :get_string],
      'Firmware' => ['TAG_FIRMWARE', :get_string],
      'Software' => ['TAG_SOFTWARE', :get_string],
      'Auto Bracket' => ['TAG_AUTO_BRACKET', :get_string],
    }
  end

  class SonyType1MakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.SonyType1MakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.SonyType1MakernoteDirectory
    end

    TAGS = {
      'Camera Info' => ['TAG_CAMERA_INFO', :get_string],
      'Focus Info' => ['TAG_FOCUS_INFO', :get_string],
      'Image Quality' => ['TAG_IMAGE_QUALITY', :get_string],
      'Flash Exposure Comp' => ['TAG_FLASH_EXPOSURE_COMP', :get_string],
      'Teleconverter' => ['TAG_TELECONVERTER', :get_string],
      'White Balance Fine Tune' => ['TAG_WHITE_BALANCE_FINE_TUNE', :get_string],
      'Camera Settings' => ['TAG_CAMERA_SETTINGS', :get_string],
      'White Balance' => ['TAG_WHITE_BALANCE', :get_string],
      'Extra Info' => ['TAG_EXTRA_INFO', :get_string],
      'Print Image Matching Info' => ['TAG_PRINT_IMAGE_MATCHING_INFO', :get_string],
      'Multi Burst Mode' => ['TAG_MULTI_BURST_MODE', :get_string],
      'Multi Burst Image Width' => ['TAG_MULTI_BURST_IMAGE_WIDTH', :get_long],
      'Multi Burst Image Height' => ['TAG_MULTI_BURST_IMAGE_HEIGHT', :get_long],
      'Panorama' => ['TAG_PANORAMA', :get_string],
      'Preview Image' => ['TAG_PREVIEW_IMAGE', :get_string],
      'Rating' => ['TAG_RATING', :get_string],
      'Contrast' => ['TAG_CONTRAST', :get_string],
      'Saturation' => ['TAG_SATURATION', :get_string],
      'Sharpness' => ['TAG_SHARPNESS', :get_string],
      'Brightness' => ['TAG_BRIGHTNESS', :get_string],
      'Long Exposure Noise Reduction' => ['TAG_LONG_EXPOSURE_NOISE_REDUCTION', :get_string],
      'High Iso Noise Reduction' => ['TAG_HIGH_ISO_NOISE_REDUCTION', :get_string],
      'Hdr' => ['TAG_HDR', :get_string],
      'Multi Frame Noise Reduction' => ['TAG_MULTI_FRAME_NOISE_REDUCTION', :get_string],
      'Picture Effect' => ['TAG_PICTURE_EFFECT', :get_string],
      'Soft Skin Effect' => ['TAG_SOFT_SKIN_EFFECT', :get_string],
      'Vignetting Correction' => ['TAG_VIGNETTING_CORRECTION', :get_string],
      'Lateral Chromatic Aberration' => ['TAG_LATERAL_CHROMATIC_ABERRATION', :get_string],
      'Distortion Correction' => ['TAG_DISTORTION_CORRECTION', :get_string],
      'Wb Shift Amber Magenta' => ['TAG_WB_SHIFT_AMBER_MAGENTA', :get_string],
      'Auto Portrait Framed' => ['TAG_AUTO_PORTRAIT_FRAMED', :get_string],
      'Focus Mode' => ['TAG_FOCUS_MODE', :get_string],
      'Af Point Selected' => ['TAG_AF_POINT_SELECTED', :get_string],
      'Shot Info' => ['TAG_SHOT_INFO', :get_string],
      'File Format' => ['TAG_FILE_FORMAT', :get_string],
      'Sony Model Id' => ['TAG_SONY_MODEL_ID', :get_string],
      'Color Mode Setting' => ['TAG_COLOR_MODE_SETTING', :get_string],
      'Color Temperature' => ['TAG_COLOR_TEMPERATURE', :get_string],
      'Color Compensation Filter' => ['TAG_COLOR_COMPENSATION_FILTER', :get_string],
      'Scene Mode' => ['TAG_SCENE_MODE', :get_string],
      'Zone Matching' => ['TAG_ZONE_MATCHING', :get_string],
      'Dynamic Range Optimiser' => ['TAG_DYNAMIC_RANGE_OPTIMISER', :get_string],
      'Image Stabilisation' => ['TAG_IMAGE_STABILISATION', :get_string],
      'Lens Id' => ['TAG_LENS_ID', :get_string],
      'Minolta Makernote' => ['TAG_MINOLTA_MAKERNOTE', :get_string],
      'Color Mode' => ['TAG_COLOR_MODE', :get_string],
      'Lens Spec' => ['TAG_LENS_SPEC', :get_string],
      'Full Image Size' => ['TAG_FULL_IMAGE_SIZE', :get_string],
      'Preview Image Size' => ['TAG_PREVIEW_IMAGE_SIZE', :get_string],
      'Macro' => ['TAG_MACRO', :get_string],
      'Exposure Mode' => ['TAG_EXPOSURE_MODE', :get_string],
      'Focus Mode 2' => ['TAG_FOCUS_MODE_2', :get_string],
      'Af Mode' => ['TAG_AF_MODE', :get_string],
      'Af Illuminator' => ['TAG_AF_ILLUMINATOR', :get_string],
      'Jpeg Quality' => ['TAG_JPEG_QUALITY', :get_string],
      'Flash Level' => ['TAG_FLASH_LEVEL', :get_string],
      'Release Mode' => ['TAG_RELEASE_MODE', :get_string],
      'Sequence Number' => ['TAG_SEQUENCE_NUMBER', :get_string],
      'Anti Blur' => ['TAG_ANTI_BLUR', :get_string],
      'Long Exposure Noise Reduction Or Focus Mode' => ['TAG_LONG_EXPOSURE_NOISE_REDUCTION_OR_FOCUS_MODE', :get_string],
      'Dynamic Range Optimizer' => ['TAG_DYNAMIC_RANGE_OPTIMIZER', :get_string],
      'High Iso Noise Reduction 2' => ['TAG_HIGH_ISO_NOISE_REDUCTION_2', :get_string],
      'Intelligent Auto' => ['TAG_INTELLIGENT_AUTO', :get_string],
      'White Balance 2' => ['TAG_WHITE_BALANCE_2', :get_string],
      'No Print' => ['TAG_NO_PRINT', :get_string],
    }
  end

  class SonyType6MakernoteDirectory < Directory
    java_import com.drew.metadata.exif.makernotes.SonyType6MakernoteDirectory

    def self.directory_class
      com.drew.metadata.exif.makernotes.SonyType6MakernoteDirectory
    end

    TAGS = {
      'Makernote Thumb Offset' => ['TAG_MAKERNOTE_THUMB_OFFSET', :get_string],
      'Makernote Thumb Length' => ['TAG_MAKERNOTE_THUMB_LENGTH', :get_string],
      'Unknown 1' => ['TAG_UNKNOWN_1', :get_string],
      'Makernote Thumb Version' => ['TAG_MAKERNOTE_THUMB_VERSION', :get_string],
    }
  end

  class GifHeaderDirectory < Directory
    java_import com.drew.metadata.gif.GifHeaderDirectory

    def self.directory_class
      com.drew.metadata.gif.GifHeaderDirectory
    end

    TAGS = {
      'Gif Format Version' => ['TAG_GIF_FORMAT_VERSION', :get_string],
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Color Table Size' => ['TAG_COLOR_TABLE_SIZE', :get_string],
      'Is Color Table Sorted' => ['TAG_IS_COLOR_TABLE_SORTED', :get_string],
      'Bits Per Pixel' => ['TAG_BITS_PER_PIXEL', :get_string],
      'Has Global Color Table' => ['TAG_HAS_GLOBAL_COLOR_TABLE', :get_string],
      'Transparent Color Index' => ['TAG_TRANSPARENT_COLOR_INDEX', :get_string],
      'Pixel Aspect Ratio' => ['TAG_PIXEL_ASPECT_RATIO', :get_string],
    }
  end

  class IccDirectory < Directory
    java_import com.drew.metadata.icc.IccDirectory

    def self.directory_class
      com.drew.metadata.icc.IccDirectory
    end

    TAGS = {
      'Profile Byte Count' => ['TAG_PROFILE_BYTE_COUNT', :get_string],
      'Cmm Type' => ['TAG_CMM_TYPE', :get_string],
      'Profile Version' => ['TAG_PROFILE_VERSION', :get_string],
      'Profile Class' => ['TAG_PROFILE_CLASS', :get_string],
      'Color Space' => ['TAG_COLOR_SPACE', :get_string],
      'Profile Connection Space' => ['TAG_PROFILE_CONNECTION_SPACE', :get_string],
      'Profile Datetime' => ['TAG_PROFILE_DATETIME', :get_string],
      'Signature' => ['TAG_SIGNATURE', :get_string],
      'Platform' => ['TAG_PLATFORM', :get_string],
      'Cmm Flags' => ['TAG_CMM_FLAGS', :get_string],
      'Device Make' => ['TAG_DEVICE_MAKE', :get_string],
      'Device Model' => ['TAG_DEVICE_MODEL', :get_string],
      'Device Attr' => ['TAG_DEVICE_ATTR', :get_string],
      'Rendering Intent' => ['TAG_RENDERING_INTENT', :get_string],
      'Xyz Values' => ['TAG_XYZ_VALUES', :get_string],
      'Profile Creator' => ['TAG_PROFILE_CREATOR', :get_string],
      'Count' => ['TAG_COUNT', :get_string],
      'A2b0' => ['TAG_A2B0', :get_string],
      'A2b1' => ['TAG_A2B1', :get_string],
      'A2b2' => ['TAG_A2B2', :get_string],
      'Bxyz' => ['TAG_bXYZ', :get_string],
      'Btrc' => ['TAG_bTRC', :get_string],
      'B2a0' => ['TAG_B2A0', :get_string],
      'B2a1' => ['TAG_B2A1', :get_string],
      'B2a2' => ['TAG_B2A2', :get_string],
      'Calt' => ['TAG_calt', :get_string],
      'Targ' => ['TAG_targ', :get_string],
      'Chad' => ['TAG_chad', :get_string],
      'Chrm' => ['TAG_chrm', :get_string],
      'Cprt' => ['TAG_cprt', :get_string],
      'Crdi' => ['TAG_crdi', :get_string],
      'Dmnd' => ['TAG_dmnd', :get_string],
      'Dmdd' => ['TAG_dmdd', :get_string],
      'Devs' => ['TAG_devs', :get_string],
      'Gamt' => ['TAG_gamt', :get_string],
      'Ktrc' => ['TAG_kTRC', :get_string],
      'Gxyz' => ['TAG_gXYZ', :get_string],
      'Gtrc' => ['TAG_gTRC', :get_string],
      'Lumi' => ['TAG_lumi', :get_string],
      'Meas' => ['TAG_meas', :get_string],
      'Bkpt' => ['TAG_bkpt', :get_string],
      'Wtpt' => ['TAG_wtpt', :get_string],
      'Ncol' => ['TAG_ncol', :get_string],
      'Ncl2' => ['TAG_ncl2', :get_string],
      'Resp' => ['TAG_resp', :get_string],
      'Pre0' => ['TAG_pre0', :get_string],
      'Pre1' => ['TAG_pre1', :get_string],
      'Pre2' => ['TAG_pre2', :get_string],
      'Desc' => ['TAG_desc', :get_string],
      'Pseq' => ['TAG_pseq', :get_string],
      'Psd0' => ['TAG_psd0', :get_string],
      'Psd1' => ['TAG_psd1', :get_string],
      'Psd2' => ['TAG_psd2', :get_string],
      'Psd3' => ['TAG_psd3', :get_string],
      'Ps2s' => ['TAG_ps2s', :get_string],
      'Ps2i' => ['TAG_ps2i', :get_string],
      'Rxyz' => ['TAG_rXYZ', :get_string],
      'Rtrc' => ['TAG_rTRC', :get_string],
      'Scrd' => ['TAG_scrd', :get_string],
      'Scrn' => ['TAG_scrn', :get_string],
      'Tech' => ['TAG_tech', :get_string],
      'Bfd' => ['TAG_bfd', :get_string],
      'Vued' => ['TAG_vued', :get_string],
      'View' => ['TAG_view', :get_string],
      'Apple Multi Language Profile Name' => ['TAG_APPLE_MULTI_LANGUAGE_PROFILE_NAME', :get_string],
    }
  end

  class IptcDirectory < Directory
    java_import com.drew.metadata.iptc.IptcDirectory

    def self.directory_class
      com.drew.metadata.iptc.IptcDirectory
    end

    TAGS = {
      'Envelope Record Version' => ['TAG_ENVELOPE_RECORD_VERSION', :get_string],
      'Destination' => ['TAG_DESTINATION', :get_string],
      'File Format' => ['TAG_FILE_FORMAT', :get_string],
      'File Version' => ['TAG_FILE_VERSION', :get_string],
      'Service Id' => ['TAG_SERVICE_ID', :get_string],
      'Envelope Number' => ['TAG_ENVELOPE_NUMBER', :get_string],
      'Product Id' => ['TAG_PRODUCT_ID', :get_string],
      'Envelope Priority' => ['TAG_ENVELOPE_PRIORITY', :get_string],
      'Date Sent' => ['TAG_DATE_SENT', :get_string],
      'Time Sent' => ['TAG_TIME_SENT', :get_string],
      'Coded Character Set' => ['TAG_CODED_CHARACTER_SET', :get_string],
      'Unique Object Name' => ['TAG_UNIQUE_OBJECT_NAME', :get_string],
      'Arm Identifier' => ['TAG_ARM_IDENTIFIER', :get_string],
      'Arm Version' => ['TAG_ARM_VERSION', :get_string],
      'Application Record Version' => ['TAG_APPLICATION_RECORD_VERSION', :get_string],
      'Object Type Reference' => ['TAG_OBJECT_TYPE_REFERENCE', :get_string],
      'Object Attribute Reference' => ['TAG_OBJECT_ATTRIBUTE_REFERENCE', :get_string],
      'Object Name' => ['TAG_OBJECT_NAME', :get_string],
      'Edit Status' => ['TAG_EDIT_STATUS', :get_string],
      'Editorial Update' => ['TAG_EDITORIAL_UPDATE', :get_string],
      'Urgency' => ['TAG_URGENCY', :get_string],
      'Subject Reference' => ['TAG_SUBJECT_REFERENCE', :get_string],
      'Category' => ['TAG_CATEGORY', :get_string],
      'Supplemental Categories' => ['TAG_SUPPLEMENTAL_CATEGORIES', :get_string],
      'Fixture Id' => ['TAG_FIXTURE_ID', :get_string],
      'Keywords' => ['TAG_KEYWORDS', :get_string],
      'Content Location Code' => ['TAG_CONTENT_LOCATION_CODE', :get_string],
      'Content Location Name' => ['TAG_CONTENT_LOCATION_NAME', :get_string],
      'Release Date' => ['TAG_RELEASE_DATE', :get_string],
      'Release Time' => ['TAG_RELEASE_TIME', :get_string],
      'Expiration Date' => ['TAG_EXPIRATION_DATE', :get_string],
      'Expiration Time' => ['TAG_EXPIRATION_TIME', :get_string],
      'Special Instructions' => ['TAG_SPECIAL_INSTRUCTIONS', :get_string],
      'Action Advised' => ['TAG_ACTION_ADVISED', :get_string],
      'Reference Service' => ['TAG_REFERENCE_SERVICE', :get_string],
      'Reference Date' => ['TAG_REFERENCE_DATE', :get_string],
      'Reference Number' => ['TAG_REFERENCE_NUMBER', :get_string],
      'Date Created' => ['TAG_DATE_CREATED', :get_string],
      'Time Created' => ['TAG_TIME_CREATED', :get_string],
      'Digital Date Created' => ['TAG_DIGITAL_DATE_CREATED', :get_string],
      'Digital Time Created' => ['TAG_DIGITAL_TIME_CREATED', :get_string],
      'Originating Program' => ['TAG_ORIGINATING_PROGRAM', :get_string],
      'Program Version' => ['TAG_PROGRAM_VERSION', :get_string],
      'Object Cycle' => ['TAG_OBJECT_CYCLE', :get_string],
      'By Line' => ['TAG_BY_LINE', :get_string],
      'By Line Title' => ['TAG_BY_LINE_TITLE', :get_string],
      'City' => ['TAG_CITY', :get_string],
      'Sub Location' => ['TAG_SUB_LOCATION', :get_string],
      'Province Or State' => ['TAG_PROVINCE_OR_STATE', :get_string],
      'Country Or Primary Location Code' => ['TAG_COUNTRY_OR_PRIMARY_LOCATION_CODE', :get_string],
      'Country Or Primary Location Name' => ['TAG_COUNTRY_OR_PRIMARY_LOCATION_NAME', :get_string],
      'Original Transmission Reference' => ['TAG_ORIGINAL_TRANSMISSION_REFERENCE', :get_string],
      'Headline' => ['TAG_HEADLINE', :get_string],
      'Credit' => ['TAG_CREDIT', :get_string],
      'Source' => ['TAG_SOURCE', :get_string],
      'Copyright Notice' => ['TAG_COPYRIGHT_NOTICE', :get_string],
      'Contact' => ['TAG_CONTACT', :get_string],
      'Caption' => ['TAG_CAPTION', :get_string],
      'Local Caption' => ['TAG_LOCAL_CAPTION', :get_string],
      'Caption Writer' => ['TAG_CAPTION_WRITER', :get_string],
      'Rasterized Caption' => ['TAG_RASTERIZED_CAPTION', :get_string],
      'Image Type' => ['TAG_IMAGE_TYPE', :get_string],
      'Image Orientation' => ['TAG_IMAGE_ORIENTATION', :get_string],
      'Language Identifier' => ['TAG_LANGUAGE_IDENTIFIER', :get_string],
      'Audio Type' => ['TAG_AUDIO_TYPE', :get_string],
      'Audio Sampling Rate' => ['TAG_AUDIO_SAMPLING_RATE', :get_string],
      'Audio Sampling Resolution' => ['TAG_AUDIO_SAMPLING_RESOLUTION', :get_string],
      'Audio Duration' => ['TAG_AUDIO_DURATION', :get_string],
      'Audio Outcue' => ['TAG_AUDIO_OUTCUE', :get_string],
      'Job Id' => ['TAG_JOB_ID', :get_string],
      'Master Document Id' => ['TAG_MASTER_DOCUMENT_ID', :get_string],
      'Short Document Id' => ['TAG_SHORT_DOCUMENT_ID', :get_string],
      'Unique Document Id' => ['TAG_UNIQUE_DOCUMENT_ID', :get_string],
      'Owner Id' => ['TAG_OWNER_ID', :get_string],
      'Object Preview File Format' => ['TAG_OBJECT_PREVIEW_FILE_FORMAT', :get_string],
      'Object Preview File Format Version' => ['TAG_OBJECT_PREVIEW_FILE_FORMAT_VERSION', :get_string],
      'Object Preview Data' => ['TAG_OBJECT_PREVIEW_DATA', :get_string],
    }
  end

  class JfifDirectory < Directory
    java_import com.drew.metadata.jfif.JfifDirectory

    def self.directory_class
      com.drew.metadata.jfif.JfifDirectory
    end

    TAGS = {
      'Version' => ['TAG_VERSION', :get_string],
      'Units' => ['TAG_UNITS', :get_string],
      'Resx' => ['TAG_RESX', :get_string],
      'Resy' => ['TAG_RESY', :get_string],
    }
  end

  class JpegCommentDirectory < Directory
    java_import com.drew.metadata.jpeg.JpegCommentDirectory

    def self.directory_class
      com.drew.metadata.jpeg.JpegCommentDirectory
    end

    TAGS = {
      'Comment' => ['TAG_COMMENT', :get_string],
    }
  end

  class JpegDirectory < Directory
    java_import com.drew.metadata.jpeg.JpegDirectory

    def self.directory_class
      com.drew.metadata.jpeg.JpegDirectory
    end

    TAGS = {
      'Compression Type' => ['TAG_COMPRESSION_TYPE', :get_string],
      'Data Precision' => ['TAG_DATA_PRECISION', :get_string],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Number Of Components' => ['TAG_NUMBER_OF_COMPONENTS', :get_string],
      'Component Data 1' => ['TAG_COMPONENT_DATA_1', :get_string],
      'Component Data 2' => ['TAG_COMPONENT_DATA_2', :get_string],
      'Component Data 3' => ['TAG_COMPONENT_DATA_3', :get_string],
      'Component Data 4' => ['TAG_COMPONENT_DATA_4', :get_string],
    }
  end

  class PhotoshopDirectory < Directory
    java_import com.drew.metadata.photoshop.PhotoshopDirectory

    def self.directory_class
      com.drew.metadata.photoshop.PhotoshopDirectory
    end

    TAGS = {
      'Channels Rows Columns Depth Mode' => ['TAG_CHANNELS_ROWS_COLUMNS_DEPTH_MODE', :get_string],
      'Mac Print Info' => ['TAG_MAC_PRINT_INFO', :get_string],
      'Xml' => ['TAG_XML', :get_string],
      'Indexed Color Table' => ['TAG_INDEXED_COLOR_TABLE', :get_string],
      'Resolution Info' => ['TAG_RESOLUTION_INFO', :get_string],
      'Alpha Channels' => ['TAG_ALPHA_CHANNELS', :get_string],
      'Display Info' => ['TAG_DISPLAY_INFO', :get_string],
      'Caption' => ['TAG_CAPTION', :get_string],
      'Border Information' => ['TAG_BORDER_INFORMATION', :get_string],
      'Background Color' => ['TAG_BACKGROUND_COLOR', :get_string],
      'Print Flags' => ['TAG_PRINT_FLAGS', :get_string],
      'Grayscale And Multichannel Halftoning Information' => ['TAG_GRAYSCALE_AND_MULTICHANNEL_HALFTONING_INFORMATION', :get_string],
      'Color Halftoning Information' => ['TAG_COLOR_HALFTONING_INFORMATION', :get_string],
      'Duotone Halftoning Information' => ['TAG_DUOTONE_HALFTONING_INFORMATION', :get_string],
      'Grayscale And Multichannel Transfer Function' => ['TAG_GRAYSCALE_AND_MULTICHANNEL_TRANSFER_FUNCTION', :get_string],
      'Color Transfer Functions' => ['TAG_COLOR_TRANSFER_FUNCTIONS', :get_string],
      'Duotone Transfer Functions' => ['TAG_DUOTONE_TRANSFER_FUNCTIONS', :get_string],
      'Duotone Image Information' => ['TAG_DUOTONE_IMAGE_INFORMATION', :get_string],
      'Effective Black And White Values' => ['TAG_EFFECTIVE_BLACK_AND_WHITE_VALUES', :get_string],
      'Eps Options' => ['TAG_EPS_OPTIONS', :get_string],
      'Quick Mask Information' => ['TAG_QUICK_MASK_INFORMATION', :get_string],
      'Layer State Information' => ['TAG_LAYER_STATE_INFORMATION', :get_string],
      'Layers Group Information' => ['TAG_LAYERS_GROUP_INFORMATION', :get_string],
      'Iptc' => ['TAG_IPTC', :get_string],
      'Image Mode For Raw Format Files' => ['TAG_IMAGE_MODE_FOR_RAW_FORMAT_FILES', :get_string],
      'Jpeg Quality' => ['TAG_JPEG_QUALITY', :get_string],
      'Grid And Guides Information' => ['TAG_GRID_AND_GUIDES_INFORMATION', :get_string],
      'Thumbnail Old' => ['TAG_THUMBNAIL_OLD', :get_string],
      'Copyright' => ['TAG_COPYRIGHT', :get_string],
      'Url' => ['TAG_URL', :get_string],
      'Thumbnail' => ['TAG_THUMBNAIL', :get_string],
      'Global Angle' => ['TAG_GLOBAL_ANGLE', :get_string],
      'Icc Untagged Profile' => ['TAG_ICC_UNTAGGED_PROFILE', :get_string],
      'Seed Number' => ['TAG_SEED_NUMBER', :get_string],
      'Global Altitude' => ['TAG_GLOBAL_ALTITUDE', :get_string],
      'Slices' => ['TAG_SLICES', :get_string],
      'Url List' => ['TAG_URL_LIST', :get_string],
      'Version' => ['TAG_VERSION', :get_string],
      'Caption Digest' => ['TAG_CAPTION_DIGEST', :get_string],
      'Print Scale' => ['TAG_PRINT_SCALE', :get_string],
      'Pixel Aspect Ratio' => ['TAG_PIXEL_ASPECT_RATIO', :get_string],
      'Print Info' => ['TAG_PRINT_INFO', :get_string],
      'Print Flags Info' => ['TAG_PRINT_FLAGS_INFO', :get_string],
    }
  end

  class PsdHeaderDirectory < Directory
    java_import com.drew.metadata.photoshop.PsdHeaderDirectory

    def self.directory_class
      com.drew.metadata.photoshop.PsdHeaderDirectory
    end

    TAGS = {
      'Channel Count' => ['TAG_CHANNEL_COUNT', :get_string],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Bits Per Channel' => ['TAG_BITS_PER_CHANNEL', :get_string],
      'Color Mode' => ['TAG_COLOR_MODE', :get_string],
    }
  end

  class PngChromaticitiesDirectory < Directory
    java_import com.drew.metadata.png.PngChromaticitiesDirectory

    def self.directory_class
      com.drew.metadata.png.PngChromaticitiesDirectory
    end

    TAGS = {
      'White Point X' => ['TAG_WHITE_POINT_X', :get_string],
      'White Point Y' => ['TAG_WHITE_POINT_Y', :get_string],
      'Red X' => ['TAG_RED_X', :get_string],
      'Red Y' => ['TAG_RED_Y', :get_string],
      'Green X' => ['TAG_GREEN_X', :get_string],
      'Green Y' => ['TAG_GREEN_Y', :get_string],
      'Blue X' => ['TAG_BLUE_X', :get_string],
      'Blue Y' => ['TAG_BLUE_Y', :get_string],
    }
  end

  class PngDirectory < Directory
    java_import com.drew.metadata.png.PngDirectory

    def self.directory_class
      com.drew.metadata.png.PngDirectory
    end

    TAGS = {
      'Image Width' => ['TAG_IMAGE_WIDTH', :get_long],
      'Image Height' => ['TAG_IMAGE_HEIGHT', :get_long],
      'Bits Per Sample' => ['TAG_BITS_PER_SAMPLE', :get_string],
      'Color Type' => ['TAG_COLOR_TYPE', :get_string],
      'Compression Type' => ['TAG_COMPRESSION_TYPE', :get_string],
      'Filter Method' => ['TAG_FILTER_METHOD', :get_string],
      'Interlace Method' => ['TAG_INTERLACE_METHOD', :get_string],
      'Palette Size' => ['TAG_PALETTE_SIZE', :get_string],
      'Palette Has Transparency' => ['TAG_PALETTE_HAS_TRANSPARENCY', :get_string],
      'Srgb Rendering Intent' => ['TAG_SRGB_RENDERING_INTENT', :get_string],
      'Gamma' => ['TAG_GAMMA', :get_string],
      'Profile Name' => ['TAG_PROFILE_NAME', :get_string],
      'Textual Data' => ['TAG_TEXTUAL_DATA', :get_string],
      'Last Modification Time' => ['TAG_LAST_MODIFICATION_TIME', :get_string],
      'Background Color' => ['TAG_BACKGROUND_COLOR', :get_string],
    }
  end

  class XmpDirectory < Directory
    java_import com.drew.metadata.xmp.XmpDirectory

    def self.directory_class
      com.drew.metadata.xmp.XmpDirectory
    end

    TAGS = {
      'Make' => ['TAG_MAKE', :get_string],
      'Model' => ['TAG_MODEL', :get_string],
      'Exposure Time' => ['TAG_EXPOSURE_TIME', :get_string],
      'Shutter Speed' => ['TAG_SHUTTER_SPEED', :get_string],
      'F Number' => ['TAG_F_NUMBER', :get_string],
      'Lens Info' => ['TAG_LENS_INFO', :get_string],
      'Lens' => ['TAG_LENS', :get_string],
      'Camera Serial Number' => ['TAG_CAMERA_SERIAL_NUMBER', :get_string],
      'Firmware' => ['TAG_FIRMWARE', :get_string],
      'Focal Length' => ['TAG_FOCAL_LENGTH', :get_string],
      'Aperture Value' => ['TAG_APERTURE_VALUE', :get_string],
      'Exposure Program' => ['TAG_EXPOSURE_PROGRAM', :get_string],
      'Datetime Original' => ['TAG_DATETIME_ORIGINAL', :get_string],
      'Datetime Digitized' => ['TAG_DATETIME_DIGITIZED', :get_string],
      'Rating' => ['TAG_RATING', :get_string],
    }
  end


  DIRECTORY_MAP = {
    'Adobe Jpeg' => AdobeJpegDirectory,
    'Bmp Header' => BmpHeaderDirectory,
    'Exif IFD0' => ExifIFD0Directory,
    'Exif Interop' => ExifInteropDirectory,
    'Exif Sub IFD' => ExifSubIFDDirectory,
    'Exif Thumbnail' => ExifThumbnailDirectory,
    'Gps' => GpsDirectory,
    'Canon Makernote' => CanonMakernoteDirectory,
    'Casio Type 1 Makernote' => CasioType1MakernoteDirectory,
    'Casio Type 2 Makernote' => CasioType2MakernoteDirectory,
    'Fujifilm Makernote' => FujifilmMakernoteDirectory,
    'Kyocera Makernote' => KyoceraMakernoteDirectory,
    'Leica Makernote' => LeicaMakernoteDirectory,
    'Nikon Type 1 Makernote' => NikonType1MakernoteDirectory,
    'Nikon Type 2 Makernote' => NikonType2MakernoteDirectory,
    'Olympus Makernote' => OlympusMakernoteDirectory,
    'Panasonic Makernote' => PanasonicMakernoteDirectory,
    'Pentax Makernote' => PentaxMakernoteDirectory,
    'Ricoh Makernote' => RicohMakernoteDirectory,
    'Sanyo Makernote' => SanyoMakernoteDirectory,
    'Sigma Makernote' => SigmaMakernoteDirectory,
    'Sony Type 1 Makernote' => SonyType1MakernoteDirectory,
    'Sony Type 6 Makernote' => SonyType6MakernoteDirectory,
    'Gif Header' => GifHeaderDirectory,
    'Icc' => IccDirectory,
    'Iptc' => IptcDirectory,
    'Jfif' => JfifDirectory,
    'Jpeg Comment' => JpegCommentDirectory,
    'Jpeg' => JpegDirectory,
    'Photoshop' => PhotoshopDirectory,
    'Psd Header' => PsdHeaderDirectory,
    'Png Chromaticities' => PngChromaticitiesDirectory,
    'Png' => PngDirectory,
    'Xmp' => XmpDirectory,

    # Aliases
    'IFD0' => ExifIFD0Directory,
  }  
end
