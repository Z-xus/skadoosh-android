const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');

class R2StorageService {
  constructor() {
    this.client = new S3Client({
      region: process.env.R2_REGION || 'auto',
      endpoint: process.env.R2_ENDPOINT,
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
      },
    });
    this.bucketName = process.env.R2_BUCKET_NAME || 'skadoosh-notes-images';
  }

  /**
   * Generate a unique file path for an image
   * @param {string} syncGroupId - The sync group ID
   * @param {string} noteId - The note ID (optional)
   * @param {string} originalFilename - The original filename
   * @returns {string} The generated file path
   */
  generateFilePath(syncGroupId, noteId, originalFilename) {
    const timestamp = Date.now();
    const randomId = crypto.randomUUID();
    const extension = originalFilename.split('.').pop();
    
    if (noteId) {
      return `${syncGroupId}/${noteId}/${timestamp}_${randomId}.${extension}`;
    } else {
      return `${syncGroupId}/${timestamp}_${randomId}.${extension}`;
    }
  }

  /**
   * Upload a file to R2
   * @param {Buffer} fileBuffer - The file buffer
   * @param {string} filePath - The file path in R2
   * @param {string} contentType - The content type
   * @returns {Promise<Object>} Upload result with URL
   */
  async uploadFile(fileBuffer, filePath, contentType) {
    try {
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: filePath,
        Body: fileBuffer,
        ContentType: contentType,
        // Make images publicly accessible (optional - depends on your R2 bucket settings)
        ACL: 'public-read',
      });

      await this.client.send(command);

      // Generate the public URL
      const publicUrl = `${process.env.R2_ENDPOINT}/${this.bucketName}/${filePath}`;
      
      console.log(`✅ File uploaded successfully: ${filePath}`);
      
      return {
        success: true,
        filePath,
        publicUrl,
        size: fileBuffer.length
      };
    } catch (error) {
      console.error('❌ Error uploading file to R2:', error);
      throw error;
    }
  }

  /**
   * Get a pre-signed URL for uploading
   * @param {string} filePath - The file path in R2
   * @param {string} contentType - The content type
   * @param {number} expiresIn - Expiration time in seconds (default: 1 hour)
   * @returns {Promise<string>} Pre-signed upload URL
   */
  async getUploadUrl(filePath, contentType, expiresIn = 3600) {
    try {
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: filePath,
        ContentType: contentType,
      });

      const uploadUrl = await getSignedUrl(this.client, command, { expiresIn });
      
      console.log(`📝 Generated upload URL for: ${filePath}`);
      return uploadUrl;
    } catch (error) {
      console.error('❌ Error generating upload URL:', error);
      throw error;
    }
  }

  /**
   * Get a pre-signed URL for downloading
   * @param {string} filePath - The file path in R2
   * @param {number} expiresIn - Expiration time in seconds (default: 1 hour)
   * @returns {Promise<string>} Pre-signed download URL
   */
  async getDownloadUrl(filePath, expiresIn = 3600) {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: filePath,
      });

      const downloadUrl = await getSignedUrl(this.client, command, { expiresIn });
      
      console.log(`📥 Generated download URL for: ${filePath}`);
      return downloadUrl;
    } catch (error) {
      console.error('❌ Error generating download URL:', error);
      throw error;
    }
  }

  /**
   * Delete a file from R2
   * @param {string} filePath - The file path in R2
   * @returns {Promise<boolean>} Success status
   */
  async deleteFile(filePath) {
    try {
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: filePath,
      });

      await this.client.send(command);
      
      console.log(`🗑️  File deleted successfully: ${filePath}`);
      return true;
    } catch (error) {
      console.error('❌ Error deleting file from R2:', error);
      return false;
    }
  }

  /**
   * Check if a file exists in R2
   * @param {string} filePath - The file path in R2
   * @returns {Promise<boolean>} Whether file exists
   */
  async fileExists(filePath) {
    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: filePath,
      });

      await this.client.send(command);
      return true;
    } catch (error) {
      if (error.name === 'NotFound') {
        return false;
      }
      console.error('❌ Error checking file existence:', error);
      throw error;
    }
  }

  /**
   * Get file metadata
   * @param {string} filePath - The file path in R2
   * @returns {Promise<Object>} File metadata
   */
  async getFileMetadata(filePath) {
    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: filePath,
      });

      const response = await this.client.send(command);
      
      return {
        size: response.ContentLength,
        contentType: response.ContentType,
        lastModified: response.LastModified,
        etag: response.ETag
      };
    } catch (error) {
      console.error('❌ Error getting file metadata:', error);
      throw error;
    }
  }

  /**
   * Generate public URL for a file (if bucket allows public access)
   * @param {string} filePath - The file path in R2
   * @returns {string} Public URL
   */
  getPublicUrl(filePath) {
    return `${process.env.R2_ENDPOINT}/${this.bucketName}/${filePath}`;
  }
}

module.exports = R2StorageService;