# GPT Image 地図下地

Built-in `image_gen` を使用。提供された 871 × 449 の詳細図を参照した画像編集。生成後、外壁の四隅を基準に元図の座標へ合わせています。ラベル・操作対象は画像に含めずHTMLで表示します。ブース数や建築細部を確定するための図面ではありません。

最終プロンプト:

Use case: style-transfer / infographic-diagram.
Asset type: a text-free 2D venue floor-map base image used in an interactive conference mobile app. This is the map asset only, no device, no UI mockup.
Input image 1 is the authoritative edit target, the supplied 5F architectural plan (871 by 449). Preserve its exact top-down geometry, relative positions, proportions, corridor connectivity and framing. Do not rearrange the floor.
Create a polished, exceptionally clear, flat top-down illustrated map by restyling the supplied plan. Preserve the outer floor footprint at approximately x73..796 and y39..389 in the same 871x449 coordinate system. Keep the same white margins and aspect ratio so interactive overlays can align. No perspective, no isometric rotation.
Make public rooms clear with softly saturated solid fills: upper-left JTCC room pale lavender, lower-left UPSIDER room pale blue; upper-right Cupertino room pale coral, lower-right Material room pale mint; the two contiguous center foyers pale warm cream with no solid wall between them. Preserve the asymmetric hall partition bays and the varying left/right partition heights. Circulation aisles white. Service cores neutral pale gray-lavender, preserving separate blocks and the white aisles between them. The two restrooms flank the center-bottom entrance; public elevators are beside the upper-left foyer; retain their actual outlines but simplify tiny plumbing and mechanical details.
Use crisp thin charcoal-gray architectural outlines, white wall tops, very restrained soft contact shadow. High-quality editorial wayfinding aesthetic, clean and practical. Sponsor counters may be retained as small simple lavender rectangles at the same locations shown in the source. Leave broad room interiors visually empty for overlaid HTML names.
Remove ALL text, numbers, labels, blue badges, dimensions, magenta annotations, arrows, hatching, people, legends and symbols. Do not render any room names. Do not invent furniture, plants, seating, decorative objects, extra rooms, doors, stairs or corridors. The image must remain orthographic and geometrically faithful to the reference. Output at high resolution in the same approximately 1.94:1 landscape canvas aspect ratio.
