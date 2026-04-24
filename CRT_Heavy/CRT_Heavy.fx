#include "ReShade.fxh"

// SUVIDADE E BLUR ANALÓGICO

// 1. ESTRUTURA FÍSICA (MÁSCARA VERTICAL)
#define MASK_TYPE 1
#define MASK_STRENGTH 0.40
#define SUBPIXEL_SIZE 1.5

// 2. SCANLINES (LINHAS HORIZONTAIS)
#define SCANLINE_FREQ 1.9
#define BEAM_MIN 1.0
#define BEAM_MAX 1.0

// 3. BLUR E LUZ (O ASPECTO "SONHO" ANALÓGICO)
#define BRIGHTNESS_BOOST 1.6
#define CRT_GAMMA 1.1
#define BLOOM_SPREAD 3.5
#define SATURATION 1.4
-------------------------------------------------

// SHADER

// Função para calcular o peso da scanline
float GetScanlineWeight(float vpos_y, float luminosity)
{
    float beamWidth = lerp(BEAM_MIN, BEAM_MAX, luminosity);
    float pos = frac(vpos_y * SCANLINE_FREQ + 0.5) * 2.0 - 1.0;
    float weight = exp(-0.4 * (pos * pos) / (beamWidth * beamWidth));
    return weight;
}

float3 GetShadowMask(float2 vpos)
{
    float2 pos = vpos / SUBPIXEL_SIZE;
    float3 mask = float3(1.0, 1.0, 1.0);

    float pos_x = frac(pos.x / 3.0);
    if (pos_x < 0.333) mask = float3(1.0, 0.5, 0.5);
    else if (pos_x < 0.666) mask = float3(0.5, 1.0, 0.5);
    else mask = float3(0.5, 0.5, 1.0);

    return lerp(float3(1.0, 1.0, 1.0), mask, MASK_STRENGTH);
}

float4 PS_CRT_Soft(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;

    // Blur Multicamadas
    float3 blurred = tex2D(ReShade::BackBuffer, texcoord).rgb * 0.25;
    blurred += tex2D(ReShade::BackBuffer, texcoord + float2(pixelSize.x * BLOOM_SPREAD, 0)).rgb * 0.25;
    blurred += tex2D(ReShade::BackBuffer, texcoord - float2(pixelSize.x * BLOOM_SPREAD, 0)).rgb * 0.25;
    blurred += tex2D(ReShade::BackBuffer, texcoord + float2(0, pixelSize.y * 0.5)).rgb * 0.125;
    blurred += tex2D(ReShade::BackBuffer, texcoord - float2(0, pixelSize.y * 0.5)).rgb * 0.125;

    // Saturação
    float gray = dot(blurred, float3(0.299, 0.587, 0.114));
    blurred = lerp(float3(gray, gray, gray), blurred, SATURATION);

    // Gamma e Scanlines
    float3 linearColor = pow(abs(blurred), float3(CRT_GAMMA, CRT_GAMMA, CRT_GAMMA));
    float luminosity = dot(linearColor, float3(0.299, 0.587, 0.114));

    float scanlineWeight = GetScanlineWeight(vpos.y, luminosity);
    float3 colorWithScanlines = linearColor * scanlineWeight;

    // Máscara Vertical
    float3 mask = GetShadowMask(vpos.xy);
    float3 finalColor = colorWithScanlines * mask;

    // Boost Final
    finalColor *= BRIGHTNESS_BOOST;

    return float4(finalColor, 1.0);
}

technique CRT_Hardcore_1080p
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_CRT_Soft; }
}
