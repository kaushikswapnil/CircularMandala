class IEffect
{
  int m_FrameCount;
  int m_StartFrame;
  
  IEffect(int frameDuration)
  {
     m_FrameCount = frameDuration;
     m_StartFrame = -1;
  }
  
  boolean HasStarted()
  {
     return m_StartFrame != -1; 
  }
  
  void Start()
  {
     m_StartFrame = frameCount; 
  }
  
  boolean HasCompleted()
  {
    if (HasStarted())
    {
      return GetEndFrame() < frameCount;
    }
    
    return false;
  }
  
  void Apply(Layer layer)
  {
     if (HasStarted() && !HasCompleted())
     {
       ApplyInternal(layer);
     }
  }
  
  void ApplyInternal(Layer layer)
  {
    
  }
  
  float GetCompletionRatio()
  {
    int endFrame = GetEndFrame();
    int curFrame = frameCount;
    
    float completionRatio = 1.0f - (((float)(endFrame-curFrame))/m_FrameCount);
    return completionRatio;
  }
  
  int GetEndFrame()
  {
    return (m_StartFrame + m_FrameCount);
  }
}

class UnfurlFromCloseEffect extends IEffect
{
  float m_InitialAngle;
  
  UnfurlFromCloseEffect(int frameDuration)
  {
    super(frameDuration);
    m_InitialAngle = -10000;
  }
  
  void ApplyInternal(Layer layer)
  {
    if (m_InitialAngle == -10000)
    {
      m_InitialAngle = layer.m_AngleBetweenLoops;
    }
    
    float completionRatio = GetCompletionRatio();
    float unfurlAngle = map(completionRatio, 0.0f, 1.0f, m_InitialAngle, layer.GetIdealAngleBetweenLoops());
    layer.m_AngleBetweenLoops = unfurlAngle;
  }
}

class GradualGrowEffect extends IEffect
{
  float m_FinalRadius;
  float m_InitialRadius;
  
  GradualGrowEffect(int frameDuration, float finalRadius)
  {
    super(frameDuration); 
    m_FinalRadius = finalRadius;
    m_InitialRadius = -1000000;
  }
  
  void ApplyInternal(Layer layer)
  {
    if (m_InitialRadius == -1000000)
    {
        m_InitialRadius = layer.m_Radius;
    }
    
    float completionRatio = GetCompletionRatio(); //<>//
    float radius = map(completionRatio, 0.0f, 1.0f, m_InitialRadius, m_FinalRadius); //<>//
    
    layer.m_Radius = radius; //<>//
  }
}

class RotateEffect extends IEffect
{
  float m_RotationAngle;
  float m_InitialAngle;
  
  RotateEffect(int frameDuration, float rotationAngle)
  {
    super(frameDuration); 
    m_RotationAngle = rotationAngle;
    m_InitialAngle = -100;
  }
  
  void ApplyInternal(Layer layer)
  {
    if (m_InitialAngle == -100)
    {
        m_InitialAngle = layer.m_Angle;
    }
    
    float completionRatio = GetCompletionRatio();
    float baseAngle = (m_InitialAngle + (completionRatio * m_RotationAngle))%TWO_PI;
    
    layer.m_Angle = baseAngle;
  }
}

class InertialRotateEffect extends RotateEffect
{
  int m_InertialMode;
  float m_InertialFrameRatio;
  float m_InertialAngleRatio;
  
  InertialRotateEffect(int frameDur, float rotationAngle, float inertialFrameRatio, float inertialAngleRatio, int inertialMode)
  {
    super(frameDur, rotationAngle);
    
    m_InertialFrameRatio = min(max(0.0f, inertialFrameRatio), 1.0f);
    m_InertialAngleRatio = min(max(0.0f, inertialAngleRatio), 1.0f);
    m_InertialMode = inertialMode;
  }
  
  void ApplyInternal(Layer layer)
  {
    if (m_InitialAngle == -100)
    {
        m_InitialAngle = layer.m_Angle;
    }
    
    float completionRatio = GetCompletionRatio();
    float baseAngle = 0.0f;
    
    if (m_InertialMode == 0)
    {
      if (completionRatio <= m_InertialFrameRatio)
      {
        float maxAngle = m_InitialAngle + (m_InertialAngleRatio * m_RotationAngle);
        float effectiveCompletionRatio = completionRatio/m_InertialFrameRatio;
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, m_InitialAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
      else
      {
        float maxAngle = m_InitialAngle + m_RotationAngle;
        float minAngle = m_InitialAngle + (m_InertialAngleRatio * m_RotationAngle);
        
        float effectiveCompletionRatio = (completionRatio-m_InertialFrameRatio)/(1.0f-m_InertialFrameRatio);
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, minAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
    }
    else if (m_InertialMode == 1)
    {
      if ((1.0f-completionRatio) <= m_InertialFrameRatio)
      {
        float maxAngle = m_InitialAngle + m_RotationAngle;
        float minAngle = m_InitialAngle + ((1.0f-m_InertialAngleRatio)*m_RotationAngle);
        float effectiveCompletionRatio = (1.0f-completionRatio)/m_InertialFrameRatio;
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, minAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
      else
      {
        float maxAngle = m_InitialAngle + ((1.0f-m_InertialAngleRatio)*m_RotationAngle);
        float minAngle = m_InitialAngle;
        
        float effectiveCompletionRatio = (completionRatio)/(1.0f-m_InertialFrameRatio);
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, minAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
    }
    else if (m_InertialMode == 2)
    {
      if (completionRatio <= m_InertialFrameRatio)
      {
        float maxAngle = m_InitialAngle + (m_InertialAngleRatio * m_RotationAngle);
        float effectiveCompletionRatio = completionRatio/m_InertialFrameRatio;
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, m_InitialAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
      else if ((1.0f-completionRatio) <= m_InertialFrameRatio)
      {
        float maxAngle = m_InitialAngle + m_RotationAngle;
        float minAngle = m_InitialAngle + ((1.0f-m_InertialAngleRatio)*m_RotationAngle);
        float effectiveCompletionRatio = (1.0f-completionRatio)/m_InertialFrameRatio;
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, minAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
      else
      {
        float maxAngle = m_InitialAngle + ((1.0f-m_InertialAngleRatio)*m_RotationAngle);
        float minAngle = m_InitialAngle + (m_InertialAngleRatio * m_RotationAngle);
        
        float effectiveCompletionRatio = (completionRatio)/(1.0f-m_InertialFrameRatio);
        float effectiveAngle = map(effectiveCompletionRatio, 0.0f, 1.0f, minAngle, maxAngle);
        
        baseAngle = effectiveAngle;
      }
    }
    
    float finalAngle = baseAngle%TWO_PI;
    layer.m_Angle = finalAngle;
  }
}
