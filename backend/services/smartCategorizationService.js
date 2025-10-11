// Smart Categorization Service
// This service provides AI-powered categorization for reports

const categoryKeywords = {
  garbage_collection: [
    'garbage', 'waste', 'trash', 'rubbish', 'dump', 'dustbin', 'litter', 
    'disposal', 'collection', 'cleaning', 'sweeping', 'sanitation',
    'dirty', 'smell', 'odor', 'flies', 'rats', 'pest'
  ],
  
  road_maintenance: [
    'road', 'street', 'pothole', 'crack', 'broken', 'damaged', 'repair',
    'asphalt', 'concrete', 'pavement', 'footpath', 'sidewalk', 'pathway',
    'surface', 'construction', 'maintenance', 'fix'
  ],
  
  street_lights: [
    'light', 'lamp', 'electricity', 'power', 'dark', 'bright', 'bulb',
    'illumination', 'lighting', 'street light', 'pole', 'electric',
    'night', 'visibility', 'safety', 'broken light', 'not working'
  ],
  
  water_supply: [
    'water', 'tap', 'pipe', 'pipeline', 'leak', 'burst', 'supply',
    'pressure', 'flow', 'shortage', 'contaminated', 'dirty water',
    'no water', 'valve', 'connection', 'plumbing', 'drinking water'
  ],
  
  drainage: [
    'drain', 'sewer', 'sewage', 'overflow', 'clog', 'blocked', 'flood',
    'water logging', 'stagnant', 'manhole', 'gutter', 'canal',
    'waterlogged', 'rainwater', 'storm drain', 'blockage'
  ],
  
  public_safety: [
    'safety', 'security', 'crime', 'theft', 'robbery', 'violence',
    'danger', 'accident', 'emergency', 'police', 'patrol', 'guard',
    'protection', 'harassment', 'unsafe', 'criminal', 'incident'
  ],
  
  health_services: [
    'health', 'hospital', 'clinic', 'medical', 'doctor', 'nurse',
    'medicine', 'treatment', 'disease', 'illness', 'epidemic',
    'vaccination', 'ambulance', 'emergency', 'patient', 'healthcare'
  ],
  
  transportation: [
    'bus', 'auto', 'rickshaw', 'taxi', 'vehicle', 'transport',
    'traffic', 'signal', 'congestion', 'parking', 'stand',
    'stop', 'route', 'service', 'public transport', 'metro'
  ],
  
  noise_pollution: [
    'noise', 'loud', 'sound', 'music', 'speaker', 'horn', 'construction',
    'disturbance', 'pollution', 'party', 'festival', 'generator',
    'machine', 'vehicle noise', 'acoustic', 'decibel'
  ],
  
  air_pollution: [
    'air', 'pollution', 'smoke', 'dust', 'emission', 'smog', 'factory',
    'exhaust', 'fumes', 'burning', 'industrial', 'vehicle emission',
    'quality', 'breathing', 'asthma', 'cough'
  ],
  
  illegal_construction: [
    'illegal', 'construction', 'building', 'unauthorized', 'permit',
    'violation', 'encroachment', 'structure', 'demolition', 'planning',
    'approval', 'land', 'property', 'development'
  ],
  
  traffic_management: [
    'traffic', 'signal', 'jam', 'congestion', 'rule', 'violation',
    'parking', 'zebra crossing', 'speed', 'lane', 'intersection',
    'management', 'control', 'flow', 'vehicle'
  ],
  
  public_facilities: [
    'park', 'garden', 'playground', 'toilet', 'public', 'facility',
    'maintenance', 'bench', 'shelter', 'community', 'center',
    'library', 'hall', 'ground', 'sports'
  ]
};

const priorityKeywords = {
  critical: [
    'emergency', 'urgent', 'immediate', 'critical', 'danger', 'life',
    'death', 'fire', 'explosion', 'collapse', 'accident', 'injury',
    'bleeding', 'severe', 'crisis', 'disaster'
  ],
  
  high: [
    'important', 'serious', 'major', 'significant', 'broken', 'damaged',
    'leaking', 'flooding', 'blocked', 'safety', 'health', 'risk'
  ],
  
  medium: [
    'issue', 'problem', 'concern', 'maintenance', 'repair', 'fix',
    'improve', 'update', 'clean', 'service'
  ],
  
  low: [
    'suggestion', 'recommendation', 'minor', 'cosmetic', 'aesthetic',
    'enhancement', 'upgrade', 'convenience'
  ]
};

const urgencyKeywords = {
  emergency: [
    'emergency', 'immediate', 'now', 'asap', 'urgent', 'critical',
    'life threatening', 'danger', 'crisis', 'disaster'
  ],
  
  high: [
    'urgent', 'soon', 'priority', 'important', 'quickly', 'fast',
    'immediate attention', 'serious'
  ],
  
  medium: [
    'moderate', 'normal', 'regular', 'standard', 'typical', 'usual'
  ],
  
  low: [
    'whenever', 'eventually', 'later', 'convenience', 'minor',
    'not urgent', 'low priority'
  ]
};

class SmartCategorizationService {
  
  /**
   * Categorize a report based on title, description, and other factors
   * @param {Object} reportData - The report data to categorize
   * @returns {Object} - Categorization result with confidence score
   */
  async categorizeReport(reportData) {
    try {
      const { title, description, category, location } = reportData;
      
      // Combine title and description for analysis
      const text = `${title} ${description}`.toLowerCase();
      
      // Calculate category confidence
      const categoryResult = this.categorizeByKeywords(text, categoryKeywords);
      
      // Calculate priority
      const priorityResult = this.categorizeByKeywords(text, priorityKeywords);
      
      // Calculate urgency
      const urgencyResult = this.categorizeByKeywords(text, urgencyKeywords);
      
      // Extract keywords
      const extractedKeywords = this.extractKeywords(text);
      
      // Location-based adjustments
      const locationAdjustments = this.getLocationAdjustments(location);
      
      // Time-based adjustments (e.g., night-time reports might be more urgent)
      const timeAdjustments = this.getTimeAdjustments();
      
      return {
        suggestedCategory: categoryResult.category || category,
        confidence: categoryResult.confidence,
        suggestedPriority: priorityResult.category || 'medium',
        priorityConfidence: priorityResult.confidence,
        suggestedUrgency: urgencyResult.category || 'medium',
        urgencyConfidence: urgencyResult.confidence,
        keywords: extractedKeywords,
        locationFactors: locationAdjustments,
        timeFactors: timeAdjustments,
        recommendations: this.generateRecommendations(categoryResult, priorityResult, urgencyResult),
        estimatedResolutionTime: this.estimateResolutionTime(categoryResult.category, priorityResult.category)
      };
      
    } catch (error) {
      console.error('Smart categorization error:', error);
      return {
        suggestedCategory: reportData.category || 'others',
        confidence: 0,
        suggestedPriority: 'medium',
        priorityConfidence: 0,
        suggestedUrgency: 'medium',
        urgencyConfidence: 0,
        keywords: [],
        error: error.message
      };
    }
  }
  
  /**
   * Categorize text based on keyword matching
   * @param {string} text - Text to analyze
   * @param {Object} keywords - Category keywords object
   * @returns {Object} - Category and confidence score
   */
  categorizeByKeywords(text, keywords) {
    const scores = {};
    let totalMatches = 0;
    
    // Calculate scores for each category
    Object.keys(keywords).forEach(category => {
      let categoryScore = 0;
      let matches = 0;
      
      keywords[category].forEach(keyword => {
        const regex = new RegExp(`\\b${keyword}\\b`, 'gi');
        const keywordMatches = (text.match(regex) || []).length;
        
        if (keywordMatches > 0) {
          matches++;
          // Weight longer keywords more heavily
          categoryScore += keywordMatches * (keyword.length > 8 ? 2 : 1);
        }
      });
      
      scores[category] = {
        score: categoryScore,
        matches: matches,
        percentage: matches / keywords[category].length
      };
      
      totalMatches += categoryScore;
    });
    
    // Find the category with highest score
    let bestCategory = null;
    let bestScore = 0;
    
    Object.keys(scores).forEach(category => {
      if (scores[category].score > bestScore) {
        bestScore = scores[category].score;
        bestCategory = category;
      }
    });
    
    // Calculate confidence (0-1 scale)
    const confidence = totalMatches > 0 ? Math.min(bestScore / totalMatches, 1) : 0;
    
    return {
      category: bestCategory,
      confidence: confidence,
      scores: scores,
      totalMatches: totalMatches
    };
  }
  
  /**
   * Extract relevant keywords from text
   * @param {string} text - Text to extract keywords from
   * @returns {Array} - Array of extracted keywords
   */
  extractKeywords(text) {
    const stopWords = new Set([
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 
      'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 
      'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
      'there', 'here', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 
      'she', 'it', 'we', 'they', 'my', 'your', 'his', 'her', 'its', 'our', 'their'
    ]);
    
    const words = text.toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2 && !stopWords.has(word));
    
    // Count word frequencies
    const wordCount = {};
    words.forEach(word => {
      wordCount[word] = (wordCount[word] || 0) + 1;
    });
    
    // Return top keywords sorted by frequency
    return Object.keys(wordCount)
      .sort((a, b) => wordCount[b] - wordCount[a])
      .slice(0, 10); // Top 10 keywords
  }
  
  /**
   * Get location-based adjustments
   * @param {Object} location - Location data
   * @returns {Object} - Location adjustment factors
   */
  getLocationAdjustments(location) {
    const adjustments = {
      urbanBonus: 0,
      densityFactor: 1,
      accessibilityFactor: 1
    };
    
    if (location) {
      // Urban areas might have different priority weights
      const urbanKeywords = ['city', 'metro', 'urban', 'downtown', 'center'];
      const locationText = `${location.address || ''} ${location.city || ''}`.toLowerCase();
      
      if (urbanKeywords.some(keyword => locationText.includes(keyword))) {
        adjustments.urbanBonus = 0.1;
        adjustments.densityFactor = 1.2;
      }
      
      // Remote areas might need higher urgency
      const remoteKeywords = ['village', 'rural', 'remote', 'outskirts'];
      if (remoteKeywords.some(keyword => locationText.includes(keyword))) {
        adjustments.accessibilityFactor = 1.3;
      }
    }
    
    return adjustments;
  }
  
  /**
   * Get time-based adjustments
   * @returns {Object} - Time adjustment factors
   */
  getTimeAdjustments() {
    const now = new Date();
    const hour = now.getHours();
    const isWeekend = now.getDay() === 0 || now.getDay() === 6;
    
    return {
      isOfficeHours: hour >= 9 && hour <= 17,
      isNightTime: hour >= 22 || hour <= 6,
      isWeekend: isWeekend,
      urgencyMultiplier: (hour >= 22 || hour <= 6) ? 1.2 : 1.0
    };
  }
  
  /**
   * Generate recommendations based on categorization results
   * @param {Object} categoryResult - Category analysis result
   * @param {Object} priorityResult - Priority analysis result
   * @param {Object} urgencyResult - Urgency analysis result
   * @returns {Array} - Array of recommendations
   */
  generateRecommendations(categoryResult, priorityResult, urgencyResult) {
    const recommendations = [];
    
    // Low confidence warnings
    if (categoryResult.confidence < 0.5) {
      recommendations.push({
        type: 'warning',
        message: 'Category confidence is low. Please review and correct if necessary.'
      });
    }
    
    // Department assignment suggestions
    const departmentMap = {
      garbage_collection: 'Waste Management Department',
      road_maintenance: 'Public Works Department',
      street_lights: 'Electrical Department',
      water_supply: 'Water Supply Department',
      drainage: 'Drainage Department',
      public_safety: 'Police Department',
      health_services: 'Health Department',
      transportation: 'Transport Department'
    };
    
    if (categoryResult.category && departmentMap[categoryResult.category]) {
      recommendations.push({
        type: 'assignment',
        message: `Suggest assigning to ${departmentMap[categoryResult.category]}`
      });
    }
    
    // Priority escalation suggestions
    if (urgencyResult.category === 'emergency' || priorityResult.category === 'critical') {
      recommendations.push({
        type: 'escalation',
        message: 'Consider immediate escalation due to high priority/urgency'
      });
    }
    
    return recommendations;
  }
  
  /**
   * Estimate resolution time based on category and priority
   * @param {string} category - Report category
   * @param {string} priority - Report priority
   * @returns {number} - Estimated resolution time in hours
   */
  estimateResolutionTime(category, priority) {
    const baseTimes = {
      garbage_collection: 24,
      road_maintenance: 72,
      street_lights: 8,
      water_supply: 12,
      drainage: 48,
      public_safety: 2,
      health_services: 6,
      transportation: 48,
      noise_pollution: 24,
      air_pollution: 72,
      illegal_construction: 168,
      traffic_management: 24,
      public_facilities: 72,
      others: 48
    };
    
    const priorityMultipliers = {
      critical: 0.25,
      high: 0.5,
      medium: 1.0,
      low: 2.0
    };
    
    const baseTime = baseTimes[category] || 48;
    const multiplier = priorityMultipliers[priority] || 1.0;
    
    return Math.max(1, Math.round(baseTime * multiplier));
  }
  
  /**
   * Analyze report for duplicate detection
   * @param {Object} reportData - New report data
   * @param {Array} existingReports - Array of existing reports
   * @returns {Object} - Duplicate analysis result
   */
  async analyzeDuplicates(reportData, existingReports) {
    const duplicates = [];
    const { title, description, location, category } = reportData;
    
    const newReportText = `${title} ${description}`.toLowerCase();
    const newLocation = location.coordinates;
    
    for (const existingReport of existingReports) {
      let similarity = 0;
      
      // Text similarity (40% weight)
      const existingText = `${existingReport.title} ${existingReport.description}`.toLowerCase();
      const textSimilarity = this.calculateTextSimilarity(newReportText, existingText);
      similarity += textSimilarity * 0.4;
      
      // Location similarity (40% weight)
      if (existingReport.location?.coordinates && newLocation) {
        const distance = this.calculateDistance(
          newLocation.latitude, newLocation.longitude,
          existingReport.location.coordinates.latitude,
          existingReport.location.coordinates.longitude
        );
        
        // Consider reports within 1km as potentially similar
        const locationSimilarity = Math.max(0, 1 - (distance / 1));
        similarity += locationSimilarity * 0.4;
      }
      
      // Category similarity (20% weight)
      if (existingReport.category === category) {
        similarity += 0.2;
      }
      
      // If similarity is above threshold, consider it a potential duplicate
      if (similarity > 0.7) {
        duplicates.push({
          reportId: existingReport._id,
          similarity: similarity,
          factors: {
            textSimilarity: textSimilarity,
            locationDistance: this.calculateDistance(
              newLocation.latitude, newLocation.longitude,
              existingReport.location.coordinates.latitude,
              existingReport.location.coordinates.longitude
            ),
            sameCategory: existingReport.category === category
          }
        });
      }
    }
    
    return {
      isDuplicate: duplicates.length > 0,
      potentialDuplicates: duplicates,
      confidence: duplicates.length > 0 ? Math.max(...duplicates.map(d => d.similarity)) : 0
    };
  }
  
  /**
   * Calculate text similarity using simple word matching
   * @param {string} text1 - First text
   * @param {string} text2 - Second text
   * @returns {number} - Similarity score (0-1)
   */
  calculateTextSimilarity(text1, text2) {
    const words1 = new Set(text1.split(/\s+/));
    const words2 = new Set(text2.split(/\s+/));
    
    const intersection = new Set([...words1].filter(x => words2.has(x)));
    const union = new Set([...words1, ...words2]);
    
    return intersection.size / union.size;
  }
  
  /**
   * Calculate distance between two coordinates
   * @param {number} lat1 - Latitude 1
   * @param {number} lon1 - Longitude 1
   * @param {number} lat2 - Latitude 2
   * @param {number} lon2 - Longitude 2
   * @returns {number} - Distance in kilometers
   */
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    
    return R * c;
  }
}

module.exports = new SmartCategorizationService();