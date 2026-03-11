import SwiftUI

struct IconGenerator: View {
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.6, blue: 1.0),
                    Color(red: 0.6, green: 0.4, blue: 0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 相机图标
            Image(systemName: "camera.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(40)
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 512, height: 512)
        .clipShape(RoundedRectangle(cornerRadius: 100))
    }
}

// 添加预览提供者
struct IconGenerator_Previews: PreviewProvider {
    static var previews: some View {
        IconGenerator()
    }
} 