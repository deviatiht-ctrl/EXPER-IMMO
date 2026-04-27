import { supabase } from './supabase-client.js';

/**
 * EXPER IMMO - Storage Utility
 * Handles image uploads to Supabase Storage with drag & drop support
 */

const BUCKETS = {
    PROPERTIES: 'property-images',
    AVATARS: 'profile-avatars',
    DOCUMENTS: 'documents'
};

/**
 * Upload an image file to Supabase Storage
 * @param {File} file - The file to upload
 * @param {string} bucket - Bucket name (property-images, profile-avatars, documents)
 * @param {string} path - Path within bucket (e.g., 'property-id/filename.jpg')
 * @returns {Promise<{data: {path: string, publicUrl: string}, error: Error}>}
 */
export async function uploadImage(file, bucket, path) {
    try {
        // Validate file
        if (!file) {
            throw new Error('Aucun fichier sélectionné');
        }

        // Validate file type
        const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
        if (!allowedTypes.includes(file.type)) {
            throw new Error('Type de fichier non supporté. Utilisez JPG, PNG ou WebP');
        }

        // Validate file size (5MB for images)
        const maxSize = 5 * 1024 * 1024;
        if (file.size > maxSize) {
            throw new Error('Fichier trop volumineux. Taille maximum: 5MB');
        }

        // Generate unique filename if not provided
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
        const fullPath = path ? `${path}/${fileName}` : fileName;

        // Upload file
        const { data, error } = await supabase.storage
            .from(bucket)
            .upload(fullPath, file, {
                cacheControl: '3600',
                upsert: false
            });

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
            .from(bucket)
            .getPublicUrl(data.path);

        return {
            data: {
                path: data.path,
                publicUrl: publicUrl
            },
            error: null
        };

    } catch (error) {
        console.error('Upload error:', error);
        return { data: null, error };
    }
}

/**
 * Upload multiple images
 * @param {FileList} files - List of files to upload
 * @param {string} bucket - Bucket name
 * @param {string} path - Path within bucket
 * @returns {Promise<{data: Array, errors: Array}>}
 */
export async function uploadMultipleImages(files, bucket, path) {
    const results = [];
    const errors = [];

    for (const file of files) {
        const result = await uploadImage(file, bucket, path);
        if (result.data) {
            results.push(result.data);
        } else {
            errors.push({ file: file.name, error: result.error });
        }
    }

    return { data: results, errors };
}

/**
 * Delete an image from storage
 * @param {string} bucket - Bucket name
 * @param {string} path - Full path to file
 * @returns {Promise<{success: boolean, error: Error}>}
 */
export async function deleteImage(bucket, path) {
    try {
        const { error } = await supabase.storage
            .from(bucket)
            .remove([path]);

        return { success: true, error: null };
    } catch (error) {
        console.error('Delete error:', error);
        return { success: false, error };
    }
}

/**
 * Create a drag & drop upload zone
 * @param {HTMLElement} container - Container element
 * @param {Object} options - Configuration options
 * @returns {Object} - Controller with destroy method
 */
export function createDragDropZone(container, options = {}) {
    const {
        bucket = BUCKETS.PROPERTIES,
        path = '',
        multiple = true,
        onUpload = () => {},
        onError = () => {},
        onDragEnter = () => {},
        onDragLeave = () => {}
    } = options;

    // Create HTML structure
    container.innerHTML = `
        <div class="upload-zone" id="upload-zone">
            <div class="upload-zone-content">
                <i data-lucide="upload-cloud"></i>
                <p><strong>Glissez-déposez</strong> vos images ici</p>
                <p class="text-muted">ou <span class="upload-link">cliquez pour sélectionner</span></p>
                <p class="text-small text-muted">JPG, PNG, WebP • Max 5MB</p>
            </div>
            <input type="file" id="file-input" accept="image/jpeg,image/png,image/webp" ${multiple ? 'multiple' : ''} hidden>
        </div>
        <div class="upload-preview" id="upload-preview"></div>
    `;

    const zone = container.querySelector('#upload-zone');
    const input = container.querySelector('#file-input');
    const preview = container.querySelector('#upload-preview');

    // Prevent default drag behaviors
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        zone.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false);
    });

    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    // Highlight drop zone
    ['dragenter', 'dragover'].forEach(eventName => {
        zone.addEventListener(eventName, () => {
            zone.classList.add('dragover');
            onDragEnter();
        }, false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
        zone.addEventListener(eventName, () => {
            zone.classList.remove('dragover');
            onDragLeave();
        }, false);
    });

    // Handle dropped files
    zone.addEventListener('drop', handleDrop, false);

    // Handle click
    zone.querySelector('.upload-link').addEventListener('click', () => input.click());
    zone.addEventListener('click', (e) => {
        if (e.target === zone || e.target.closest('.upload-zone-content')) {
            input.click();
        }
    });

    // Handle file selection
    input.addEventListener('change', handleFiles, false);

    function handleDrop(e) {
        const dt = e.dataTransfer;
        const files = dt.files;
        handleFiles({ target: { files } });
    }

    async function handleFiles(e) {
        const files = [...e.target.files];
        if (files.length === 0) return;

        // Show preview
        showPreview(files);

        // Upload files
        const { data, errors } = await uploadMultipleImages(files, bucket, path);

        if (errors.length > 0) {
            errors.forEach(({ file, error }) => {
                onError(file, error);
            });
        }

        if (data.length > 0) {
            onUpload(data);
        }
    }

    function showPreview(files) {
        preview.innerHTML = files.map(file => `
            <div class="preview-item" data-name="${file.name}">
                <img src="${URL.createObjectURL(file)}" alt="${file.name}">
                <div class="preview-overlay">
                    <span class="preview-name">${file.name}</span>
                    <span class="preview-size">${formatFileSize(file.size)}</span>
                </div>
                <div class="preview-loading">
                    <div class="spinner"></div>
                </div>
            </div>
        `).join('');
    }

    function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    // Initialize icons
    if (window.lucide) {
        lucide.createIcons();
    }

    return {
        destroy() {
            // Cleanup event listeners
            ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
                zone.removeEventListener(eventName, preventDefaults);
                document.body.removeEventListener(eventName, preventDefaults);
            });
        },
        clear() {
            preview.innerHTML = '';
            input.value = '';
        }
    };
}

/**
 * Upload property images with progress tracking
 * @param {FileList} files - Image files
 * @param {string} propertyId - Property ID for folder organization
 * @param {Function} onProgress - Progress callback (uploaded, total)
 * @returns {Promise<{images: Array, errors: Array}>}
 */
export async function uploadPropertyImages(files, propertyId, onProgress = () => {}) {
    const images = [];
    const errors = [];
    let uploaded = 0;

    for (const file of files) {
        const result = await uploadImage(
            file,
            BUCKETS.PROPERTIES,
            propertyId
        );

        if (result.data) {
            images.push({
                url: result.data.publicUrl,
                path: result.data.path,
                is_primary: images.length === 0 // First image is primary
            });
        } else {
            errors.push({ file: file.name, error: result.error });
        }

        uploaded++;
        onProgress(uploaded, files.length);
    }

    return { images, errors };
}

/**
 * Upload avatar image
 * @param {File} file - Avatar image file
 * @param {string} userId - User ID
 * @returns {Promise<{url: string, error: Error}>}
 */
export async function uploadAvatar(file, userId) {
    const result = await uploadImage(file, BUCKETS.AVATARS, userId);
    
    if (result.data) {
        // Update profile with new avatar URL
        const { error } = await supabase
            .from('profiles')
            .update({ avatar_url: result.data.publicUrl })
            /* .eq('id', userId) - TODO: filter nan server */;

        if (error) {
            return { url: null, error };
        }

        return { url: result.data.publicUrl, error: null };
    }

    return { url: null, error: result.error };
}

// Export bucket names for reference
export { BUCKETS };
