import Foundation
import Supabase

func test(channel: RealtimeChannel, myAuthId: UUID) {
    let changes = channel.postgresChange(
        AnyAction.self,
        schema: "public",
        table: "user_profiles",
        filter: .eq("auth_id", value: myAuthId.uuidString)
    )
}
