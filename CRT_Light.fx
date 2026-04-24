#include "ReShade.fxh"

#define MASCARA_SCANLINE 0.35
#define BRILHO_BLOOM 1.4
#define DESFOCAR_HORIZONTAL 1.5

float4 PS_CRT_Lottes(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{

    float2 pixelSize = ReShade::PixelSize;
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float4 colorL = tex2D(ReShade::BackBuffer, texcoord - float2(pixelSize.x * DESFOCAR_HORIZONTAL, 0));
    float4 colorR = tex2D(ReShade::BackBuffer, texcoord + float2(pixelSize.x * DESFOCAR_HORIZONTAL, 0));

    float4 finalColor = (color * 0.5) + (colorL * 0.25) + (colorR * 0.25);

    float scanline = sin(vpos.y * 1.5) * MASCARA_SCANLINE + (1.0 - MASCARA_SCANLINE);
    finalColor.rgb *= scanline;

    finalColor.rgb = pow(abs(finalColor.rgb), 0.9);
    finalColor.rgb *= BRILHO_BLOOM;

    return float4(finalColor.rgb, 1.0);
}

technique CRT_Lottes_Enhanced
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CRT_Lottes;
    }
}
