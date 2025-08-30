# 🤖 Gemini AI Chatbot Setup Guide

## 🎯 Overview

Your food portfolio website now includes an intelligent AI chatbot powered by Google's Gemini AI. The chatbot can:

- Answer questions about your menu and dishes
- Provide cooking tips and culinary advice
- Help with event planning and catering inquiries
- Give personalized food recommendations
- Assist customers with general inquiries

## 🔑 Getting Your Gemini API Key

### Step 1: Get API Access
1. **Visit Google AI Studio**: Go to [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
2. **Sign in** with your Google account
3. **Create API Key**: Click "Create API Key" button
4. **Choose Project**: Select an existing Google Cloud project or create a new one
5. **Copy Your Key**: Save the generated API key securely

### Step 2: Update Environment Variables
Add your Gemini API key to your `.env` file:

```env
# Gemini AI Configuration
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

## 🚀 Testing the Integration

### 1. Check API Status
Test if your API key is working:
```bash
curl http://localhost:5000/api/chatbot/status
```

### 2. Test AI Connection
```bash
curl http://localhost:5000/api/chatbot/test
```

### 3. Send a Test Message
```bash
curl -X POST http://localhost:5000/api/chatbot/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about your menu"}'
```

## 🎨 Chatbot Features

### Frontend Features
- **Fixed Position Toggle**: Accessible from any page
- **Modern UI**: Clean, responsive chat interface
- **Quick Actions**: Pre-built buttons for common queries
- **Typing Indicators**: Shows when AI is responding
- **Message History**: Maintains conversation context
- **Mobile Responsive**: Works perfectly on all devices

### Backend Features
- **Context Awareness**: Knows about your current menu items
- **Error Handling**: Graceful fallbacks when AI is unavailable
- **Rate Limiting**: Built-in protection against abuse
- **Logging**: Comprehensive error tracking and monitoring

## 📊 API Endpoints

### Chat Endpoints
- `POST /api/chatbot/chat` - Main conversation endpoint
- `POST /api/chatbot/recommend` - Food recommendations
- `POST /api/chatbot/cooking-tip` - Cooking advice
- `GET /api/chatbot/status` - Check chatbot availability
- `GET /api/chatbot/test` - Test AI connection

### Example Request
```javascript
fetch('/api/chatbot/chat', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: "What dishes do you recommend for a vegetarian?",
    includeContext: true
  })
})
```

### Example Response
```json
{
  "success": true,
  "data": {
    "userMessage": "What dishes do you recommend for a vegetarian?",
    "aiResponse": "Based on our current menu, I'd recommend...",
    "timestamp": "2024-01-20T10:30:00.000Z",
    "contextIncluded": true
  }
}
```

## 🛡️ Security & Best Practices

### API Key Security
- ✅ **Never commit** your API key to version control
- ✅ **Store securely** in environment variables only
- ✅ **Regenerate regularly** for enhanced security
- ✅ **Monitor usage** in Google Cloud Console

### Rate Limiting
- The chatbot includes built-in rate limiting
- Free Gemini API has usage quotas
- Monitor your usage in Google AI Studio

### Error Handling
- Graceful fallbacks when AI is unavailable
- User-friendly error messages
- Automatic retry mechanisms

## 🎛️ Customization Options

### Personality & Context
Edit `server/config/gemini.js` to customize:
- AI personality and tone
- Business-specific context
- Response formatting
- Specialized knowledge areas

### UI Customization
Modify `src/components/Chatbot.css` to:
- Change colors and styling
- Adjust positioning and size
- Customize animations
- Add your branding

### Quick Actions
Update `src/components/Chatbot.jsx` to:
- Add new quick action buttons
- Customize pre-written questions
- Modify conversation starters

## 📈 Usage Analytics

### Monitoring
- Check Google AI Studio for usage statistics
- Monitor server logs for conversation patterns
- Track user engagement with chatbot features

### Optimization
- Analyze common questions to improve responses
- Update context based on user queries
- Refine quick actions based on usage

## 🚨 Troubleshooting

### Common Issues

**Chatbot shows "AI Offline"**
- Check your Gemini API key in `.env`
- Verify API key permissions in Google Cloud
- Check server logs for error messages

**Slow Responses**
- Gemini API response times vary
- Consider implementing response caching
- Monitor your API quota usage

**Context Not Working**
- Ensure Supabase connection is working
- Check that dishes are loaded in database
- Verify `includeContext: true` in requests

### Error Messages
- `Invalid API key`: Check your Gemini API key
- `Rate limit exceeded`: Wait or upgrade your plan  
- `Service unavailable`: Temporary Gemini API issues

## 🌟 Advanced Features

### Conversation Memory
Future enhancement: Store conversations in Supabase for:
- User conversation history
- Improved context awareness
- Analytics and insights

### Multi-language Support
Extend the chatbot to support multiple languages:
- Detect user language
- Respond in preferred language
- Maintain culinary context across languages

### Voice Integration
Potential additions:
- Speech-to-text input
- Text-to-speech responses
- Voice commands for quick actions

## 📞 Support

For issues with:
- **Gemini API**: Check [Google AI documentation](https://ai.google.dev/docs)
- **Implementation**: Review the code comments and error logs
- **Customization**: Modify the configuration files as needed

## 🎉 You're All Set!

Your AI-powered food portfolio chatbot is ready to:
- Engage customers 24/7
- Provide instant information about your offerings
- Enhance user experience with intelligent assistance
- Drive customer engagement and inquiries

Start the servers and test your new AI assistant!