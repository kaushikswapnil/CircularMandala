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

class ChangeAngleBetweenLoopEffect extends IEffect
{
  float m_AngleChange;
  float m_InitialAngle;
  ChangeAngleBetweenLoopEffect(int frameDuration, float angleChange)
  {
    super(frameDuration);
    m_AngleChange = angleChange;
    m_InitialAngle = -10000;
  }
  
  void ApplyInternal(Layer layer)
  {
    if (m_InitialAngle == -10000)
    {
      m_InitialAngle = layer.m_AngleBetweenLoops;
    }
    
    float completionRatio = GetCompletionRatio();
    float unfurlAngle = map(completionRatio, 0.0f, 1.0f, m_InitialAngle, GetFinalAngle(layer));
    layer.m_AngleBetweenLoops = unfurlAngle;
  }
  
  float GetFinalAngle(Layer layer)
  {
    return m_InitialAngle + m_AngleChange; 
  }
}

class UnfurlFromCloseEffect extends ChangeAngleBetweenLoopEffect
{
  UnfurlFromCloseEffect(int frameDuration)
  {
    super(frameDuration, 0.0f);
  }
  
  float GetFinalAngle(Layer layer)
  {
    return layer.GetIdealAngleBetweenLoops(); 
  }
}

class FurlToCloseEffect extends ChangeAngleBetweenLoopEffect
{
  FurlToCloseEffect(int frameDuration)
  {
    super(frameDuration, 0.0f);
  }
  
  float GetFinalAngle(Layer layer)
  {
    return 0.0f; 
  }
}

class RecedingCenteredEffect extends IEffect
{
  float m_RecedingStartRatio;
  RecedingCenteredEffect(int frameDuration, float recedingFrameRatio)
  {
    super(frameDuration); 
    m_RecedingStartRatio = recedingFrameRatio;
  }
  
  void ApplyInternal(Layer layer)
  {
    float completionRatio = GetCompletionRatio();
        
    layer.m_Center = PVector.add(CENTERVECTOR, PVector.mult(new PVector(0, -layer.m_Radius), 1.0f-completionRatio));
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
    
    float completionRatio = GetCompletionRatio();
    float radius = map(completionRatio, 0.0f, 1.0f, m_InitialRadius, m_FinalRadius);
    
    layer.m_Radius = radius;
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

    layer.m_Angle += GetFrameSpeed();
  }
  
  float GetFrameSpeed()
  {    
    float maximumFrameSpeed = GetMaximumFrameSpeed();
    
    if (IsInMaximumSpeedRange())
    {
       return maximumFrameSpeed;
    }
    else
    {
       float completionRatio = GetCompletionRatio();
       
       float effectiveSpeed = 0.0f;
       
       if (IsInertialInStart() && completionRatio < m_InertialFrameRatio)
       {
         effectiveSpeed = map(completionRatio, 0.0f, m_InertialFrameRatio, 0.0f, maximumFrameSpeed);
       }
       else if (IsInertialInEnd() && completionRatio > (1.0f- m_InertialFrameRatio))
       {
         effectiveSpeed = map(completionRatio, (1.0f- m_InertialFrameRatio), 1.0f, maximumFrameSpeed, 0.0f);
       }
       
       return effectiveSpeed; 
    }
  }
  
  boolean IsInMaximumSpeedRange()
  {
    float completionRatio = GetCompletionRatio();
    
    boolean isInMaximumSpeedRange = false;
    
    if (IsInertialInStart())
    {
      isInMaximumSpeedRange |= (completionRatio < m_InertialFrameRatio); 
    }
    
    if (IsInertialInEnd())
    {
      isInMaximumSpeedRange |= (completionRatio > (1.0f - m_InertialFrameRatio)); 
    }
    
    return isInMaximumSpeedRange;
  }
  
  float GetMaximumFrameSpeed()
  {
    float angleTraversedInFullSpeed = GetAngleTraversedInFullSpeed();
    
    int inertialRatioMultiplier = 1;
    
    if (IsInertialInStart() && IsInertialInEnd())
    {
      inertialRatioMultiplier = 2;
    }
    
    float maximumFrameSpeed = angleTraversedInFullSpeed / (m_FrameCount * (1.0f - (inertialRatioMultiplier*m_InertialFrameRatio)));
    return maximumFrameSpeed;
  }
  
  float GetAngleTraversedInFullSpeed()
  {
    boolean isInertialInStart = IsInertialInStart();
    boolean isInertialInEnd = IsInertialInEnd();
    
    float angleTraversedInFullSpeed = m_RotationAngle;
    
    if (isInertialInStart && isInertialInEnd)
    {
      angleTraversedInFullSpeed *= (1.0f - (2*m_InertialFrameRatio));
    }
    else
    {
      angleTraversedInFullSpeed *= (1.0f - (m_InertialFrameRatio));
    }
    
    return angleTraversedInFullSpeed;
  }
  
  boolean IsInertialInStart()
  {
    boolean isInertialInStart = m_InertialMode == 0 || m_InertialMode == 2;
    return isInertialInStart;
  }
  
  boolean IsInertialInEnd()
  {
    boolean isInertialInEnd = m_InertialMode == 1 || m_InertialMode == 2;
    return isInertialInEnd;
  }
}
